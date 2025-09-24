// App.js
import React, { useState } from "react";
import axios from "axios";
import crypto from "crypto-js"; // For SHA256 hashing
import certificates from "./certificates.json"; // Your JSON file

function App() {
  const [file, setFile] = useState(null);
  const [result, setResult] = useState(null);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
    setResult(null);
  };

  const handleVerify = async () => {
    if (!file) {
      alert("Please select a certificate file");
      return;
    }

    const reader = new FileReader();
    reader.onload = async (e) => {
      try {
        const fileData = e.target.result;

        // Compute SHA256 hash of file
        const wordArray = crypto.lib.WordArray.create(fileData);
        const hash = crypto.SHA256(wordArray).toString();
        console.log("Computed Hash:", hash);

        // 1️⃣ Check local JSON first
        let found = null;
        for (const certKey in certificates) {
          if (certificates[certKey].certHash === hash) {
            found = certificates[certKey];
            break;
          }
        }

        if (found) {
          setResult({
            status: "verified",
            message: "✅ Certificate Verified Locally!",
            data: found.certJSON || {},
          });
        } else {
          // 2️⃣ If not found locally, call blockchain backend
          const certJSON = JSON.parse(new TextDecoder().decode(fileData)); // Assuming JSON file
          const signatureBase64 = crypto.SHA256(JSON.stringify(certJSON)).toString();

          const response = await axios.post("http://localhost:4000/verifyFull", {
            certID: certJSON.certID || "unknown-cert",
            certJSON,
            signatureBase64,
          });

          if (response.data.success) {
            setResult({
              status: "blockchain",
              message: "✅ Verified via Blockchain!",
              data: response.data.data,
            });
          } else {
            setResult({
              status: "error",
              message: response.data.error || "Verification failed",
            });
          }
        }
      } catch (err) {
        console.error(err);
        setResult({ status: "error", message: "Error reading or verifying file", error: err.message });
      }
    };

    reader.readAsArrayBuffer(file);
  };

  return (
    <div style={{ padding: "2rem" }}>
      <h1>Certificate Verification App</h1>
      <input type="file" onChange={handleFileChange} accept=".json" />
      <button onClick={handleVerify} style={{ marginLeft: "1rem" }}>
        Verify Certificate
      </button>

      {result && (
        <div style={{ marginTop: "2rem", border: "1px solid #ccc", padding: "1rem" }}>
          <h3>Status: {result.status}</h3>
          <p>{result.message}</p>
          {result.data && (
            <pre style={{ textAlign: "left" }}>{JSON.stringify(result.data, null, 2)}</pre>
          )}
        </div>
      )}
    </div>
  );
}

export default App;
