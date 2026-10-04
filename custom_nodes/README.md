# Custom Nodes

Place JSON node definitions in this folder. Each definition may contain:

```json
{
  "name": "Vector Offset",
  "category": "Fields",
  "description": "Offsets a vector field.",
  "inputs": ["vector"],
  "outputs": ["vector"],
  "parameters": {"amount": 1.0}
}
```

Valid definitions appear in the node library when the editor starts.
