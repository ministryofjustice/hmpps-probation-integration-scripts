function getTeamByName(teamName) {
  return "trunk";
}

function onOpen() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var menuEntries = [];
  menuEntries.push({
    name: "Refresh Service Catalogue",
    functionName: "refreshData",
  });

  ss.addMenu("Refresh", menuEntries);
}

function refreshData() {
  var sheet = SpreadsheetApp.getActive().getSheetByName("ServiceCatalogueData");
  var myRange = sheet.getRange(1, 2);

  myRange.setValue(Date.now());
}

function test() {
  Logger.log(
    updateServiceArea("Intelligence & Accomodation", "test owner name"),
  );
}

var apiEndpoint = "https://service-catalogue.hmpps.service.justice.gov.uk/v1";

var headers = {
  Authorization: "Bearer <token>",
};

function fetchID(path, filter, pattern) {
  var options = {
    method: "get",
    headers: headers,
  };
  response = UrlFetchApp.fetch(
    `${apiEndpoint}/${path}?filters[${filter}]=${encodeURIComponent(pattern)}`,
    options,
  );
  json = JSON.parse(response);
  console.log(json);
  if (json.data.length === 0) {
    return null;
  }
  return json.data[0].id;
}

function testUpdateProduct() {
  updateProduct(
    "HMPPS500",
    "test probation product",
    "Subproduct",
    "Adjudications",
    "Y",
    "test description",
    "Probation 1",
    "beta",
    "Probation 2",
    "Probation 3",
    "bob dm",
    "sue pm",
    "cl",
    "gl",
  );
  //updateProduct("p001", "test product", "", null)
}

function updateProduct2(
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
) {
  if (productID == "") {
    return null;
  }

  return "Got to here 1";
}

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
) {
  if (productID == "") {
    return null;
  }

  if (legacy == "Y") {
    var legacyBool = true;
  } else {
    var legacyBool = false;
  }

  if (productType == "Subproduct") {
    var subproductBool = true;
  } else {
    var subproductBool = false;
  }

  if (parent == "") {
    var parent = null;
  } else {
    try {
      var parent = fetchID("products", "name", parent);
    } catch (err) {
      var parent = null;
    }
  }

  if (team == "") {
    var team = null;
  } else {
    var team = fetchID("teams", "name", team);
  }

  if (productSet == "") {
    var productSet = null;
  } else {
    var productSet = fetchID("product-sets", "name", productSet);
  }

  if (serviceArea == "") {
    var serviceArea = null;
  } else {
    var serviceArea = fetchID("service-areas", "name", serviceArea);
  }
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
      service_area: serviceArea,
      delivery_manager: deliveryManager,
      product_manager: productManager,
      confluence_link: confluenceLink,
      gdrive_link: gDriveLink,
    },
  };

  var options = {
    method: "get",
    headers: headers,
  };
  response = UrlFetchApp.fetch(
    `${apiEndpoint}/products?filters[p_id]=${encodeURIComponent(productID)}`,
    options,
  );
  json = JSON.parse(response);

  if (json.data.length === 0) {
    console.log(json.data);
    console.log("Empty result - POSTing new entry to Products");

    var options = {
      method: "post",
      contentType: "application/json",
      headers: headers,
      // Convert the JavaScript object to a JSON string.
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
      // Convert the JavaScript object to a JSON string.
      payload: JSON.stringify(data),
    };
    response = UrlFetchApp.fetch(
      `${apiEndpoint}/products/${scproductId}`,
      options,
    );
  }

  return response.getResponseCode();
}

function updateTeam(teamId, team) {
  if (teamId == "") {
    return null;
  }

  if (team == "") {
    return null;
  }

  var data = {
    data: {
      t_id: teamId,
      name: team,
      description: "n/a",
      slack_channel: "n/a",
    },
  };

  var options = {
    method: "get",
    headers: headers,
  };
  response = UrlFetchApp.fetch(
    `${apiEndpoint}/teams?filters[t_id]=${encodeURIComponent(teamId)}`,
    options,
  );
  json = JSON.parse(response);

  if (json.data.length === 0) {
    console.log(json.data);
    console.log("Empty result - POSTing new entry to Teams");

    var options = {
      method: "post",
      contentType: "application/json",
      headers: headers,
      // Convert the JavaScript object to a JSON string.
      payload: JSON.stringify(data),
    };
    response = UrlFetchApp.fetch(`${apiEndpoint}/teams`, options);
  } else {
    console.log("Updating existing entry, PUTing to Teams");
    var teamId = json.data[0].id;

    var options = {
      method: "put",
      contentType: "application/json",
      headers: headers,
      // Convert the JavaScript object to a JSON string.
      payload: JSON.stringify(data),
    };
    response = UrlFetchApp.fetch(`${apiEndpoint}/teams/${teamId}`, options);
  }

  return response.getResponseCode();
}

function updateProductSet(productSetId, productSet) {
  if (productSetId == "") {
    return null;
  }

  if (productSet == "") {
    return null;
  }

  var data = {
    data: {
      ps_id: productSetId,
      name: productSet,
    },
  };

  var options = {
    method: "get",
    headers: headers,
  };
  response = UrlFetchApp.fetch(
    `${apiEndpoint}/product-sets?filters[ps_id]=${encodeURIComponent(
      productSetId,
    )}`,
    options,
  );
  json = JSON.parse(response);

  if (json.data.length === 0) {
    console.log(json.data);
    console.log("Empty result - POSTing new entry to Product Sets");

    var options = {
      method: "post",
      contentType: "application/json",
      headers: headers,
      // Convert the JavaScript object to a JSON string.
      payload: JSON.stringify(data),
    };
    response = UrlFetchApp.fetch(`${apiEndpoint}/product-sets`, options);
  } else {
    console.log("Updating existing entry, PUTing to Product Sets");
    var productSetId = json.data[0].id;

    var options = {
      method: "put",
      contentType: "application/json",
      headers: headers,
      // Convert the JavaScript object to a JSON string.
      payload: JSON.stringify(data),
    };
    response = UrlFetchApp.fetch(
      `${apiEndpoint}/product-sets/${productSetId}`,
      options,
    );
  }

  return response.getResponseCode();
}

function updateServiceArea(serviceAreaId, serviceArea, owner) {
  if (serviceAreaId == "") {
    return null;
  }

  if (serviceArea == "") {
    return null;
  }

  var data = {
    data: {
      sa_id: serviceAreaId,
      name: serviceArea,
      owner: owner,
    },
  };

  var options = {
    method: "get",
    headers: headers,
  };
  response = UrlFetchApp.fetch(
    `${apiEndpoint}/service-areas?filters[sa_id]=${encodeURIComponent(
      serviceAreaId,
    )}`,
    options,
  );
  json = JSON.parse(response);

  if (json.data.length === 0) {
    console.log(json.data);
    console.log("Empty result - POSTing new entry to service catalogue");

    var options = {
      method: "post",
      contentType: "application/json",
      headers: headers,
      // Convert the JavaScript object to a JSON string.
      payload: JSON.stringify(data),
    };
    response = UrlFetchApp.fetch(`${apiEndpoint}/service-areas`, options);
  } else {
    console.log("Updating existing entry, PUTing to service catalogue");
    var serviceAreaId = json.data[0].id;

    var options = {
      method: "put",
      contentType: "application/json",
      headers: headers,
      // Convert the JavaScript object to a JSON string.
      payload: JSON.stringify(data),
    };
    response = UrlFetchApp.fetch(
      `${apiEndpoint}/service-areas/${serviceAreaId}`,
      options,
    );
  }

  return response.getResponseCode();
}
