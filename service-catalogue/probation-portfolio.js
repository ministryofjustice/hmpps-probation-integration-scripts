var apiEndpoint = "https://service-catalogue.hmpps.service.justice.gov.uk/v1";

var headers = {
  Authorization: "Bearer <token>",
};

// =updateProduct(A, C, false, "", "N", L, "team", E, "", D, "", B, "", "", R)
function updateProduct(
  productID,
  name,
  productType,
  parent,
  legacy,
  description,
  team,
  phase,
  productSet,
  serviceArea,
  deliveryManager,
  productManager,
  confluenceLink,
  gDriveLink,
  slackChannelId,
) {
  if (productID == "") {
    return null;
  }

  var legacyBool = legacy == "Y" ? true : false;
  var subproductBool = productType == "Subproduct" ? true : false;
  parent = null;
  team = null;
  productSet = null;

  // check for line breaks where data has more than one line.
  confluenceLink = confluenceLink.split("\n").join(", ");

  var data = {
    data: {
      p_id: productID,
      name: name,
      subproduct: subproductBool,
      parent: parent,
      legacy: legacyBool,
      description: description,
      team: team,
      phase: phase,
      product_set: productSet,
      service_area: fetchServiceArea(serviceArea),
      delivery_manager: deliveryManager,
      product_manager: productManager,
      confluence_link: confluenceLink,
      gdrive_link: gDriveLink,
      slack_channel_id: slackChannelId,
    },
  };

  var options = { method: "get", headers: headers };

  response = UrlFetchApp.fetch(
    `${apiEndpoint}/products?filters[p_id]=${encodeURIComponent(productID)}`,
    options,
  );

  json = JSON.parse(response);

  if (json.data.length === 0) {
    console.log("Empty result - POSTing new entry to Products");

    var options = {
      method: "post",
      contentType: "application/json",
      headers: headers,
      payload: JSON.stringify(data),
    };

    response = UrlFetchApp.fetch(`${apiEndpoint}/products`, options);
  } else {
    console.log("Updating existing entry, PUTing to Products");
    var scproductId = json.data[0].id;

    var options = {
      method: "put",
      contentType: "application/json",
      headers: headers,
      payload: JSON.stringify(data),
    };

    response = UrlFetchApp.fetch(
      `${apiEndpoint}/products/${scproductId}`,
      options,
    );
  }

  return response.getResponseCode();
}

function fetchServiceArea(serviceArea) {
  var options = {
    method: "get",
    headers: headers,
  };
  response = UrlFetchApp.fetch(
    `${apiEndpoint}/service-areas?filters[name]=${encodeURIComponent(serviceArea)}`,
    options,
  );
  json = JSON.parse(response);
  if (json.data.length === 0) {
    return null;
  }
  return json.data[0].id;
}
