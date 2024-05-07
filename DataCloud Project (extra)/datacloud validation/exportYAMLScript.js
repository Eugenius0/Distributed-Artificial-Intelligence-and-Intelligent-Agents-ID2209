const axios = require('axios');
const fs = require('fs');

async function exportYAML(username, pipelineName) {
  // API details
  const apiUrl = `http://crowdserv.sys.kth.se:8082/api/repo/exportyaml/${username}/${pipelineName}`;
  const headers = { accept: 'text/plain' };

  try {
    // Make GET request to API
    const response = await axios.get(apiUrl, { headers });

    // Check if the request was successful (status code 200)
    if (response.status === 200) {
      // Convert response data to string
      const yamlString = JSON.stringify(response.data);

      // Save YAML export to a file
      fs.writeFileSync(`${pipelineName}_export.yaml`, yamlString);
      console.log(`YAML export saved to ${pipelineName}_export.yaml`);
    } else {
      console.error(`Error: ${response.status} - ${response.data}`);
    }
  } catch (error) {
    console.error(`An error occurred: ${error.message}`);
  }
}

// Example usage
const username = 'testuser';
const pipelineName = 'DEF-SIM-PIPE';
exportYAML(username, pipelineName);
