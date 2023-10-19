using UnityEngine;

public class PlayerPositionUpdater : MonoBehaviour
{
    void Update()
    {
        // Get the player's world position
        Vector3 playerWorldPosition = transform.position;
        
        // Update the _PlayerPosition uniform accessible from all shaders
        Shader.SetGlobalVector("_PlayerPosition", playerWorldPosition);
    }
}
