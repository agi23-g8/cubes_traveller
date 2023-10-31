using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Netcode;

public class ZoomScript : NetworkBehaviour
{
    NetworkObject networkObject;

    [SerializeField]
    private float maxZoom = 90f;
    [SerializeField]
    private float minZoom = 20f;
    [SerializeField]
    private float zoomSpeed = 10f;

    public override void OnNetworkSpawn()
    {
    }

    void Start()
    {
        if (!IsClient)
        {
            networkObject = GetComponent<NetworkObject>();
            networkObject.Spawn();
        }
    }

    void Update()
    {
        if (IsClient)
        {
            //get touch input
            if (Input.touchCount == 2)
            {
                Touch first = Input.GetTouch(0);
                Touch second = Input.GetTouch(1);
                //if the touch is on the screen
                if (first.phase == TouchPhase.Moved && second.phase == TouchPhase.Moved)
                {
                    //get the change in position
                    Vector2 deltaFirst = first.deltaPosition;
                    Vector2 deltaSecond = second.deltaPosition;
                    Vector2 postionFirst = first.position;
                    Vector2 postionSecond = second.position;
                    float prevTouchDeltaMag = (postionFirst - postionSecond - (deltaFirst - deltaSecond)).magnitude;
                    float touchDeltaMag = (postionFirst - postionSecond).magnitude;
                    float deltaMagnitudeDiff = prevTouchDeltaMag - touchDeltaMag;
                    //send the change in position to the server
                    UpdateZoomServerRpc(deltaMagnitudeDiff);
                }
            }

            // send the gyro data to the server
        }
    }


    [ServerRpc(RequireOwnership = false)]
    public void UpdateZoomServerRpc(float zoom, ServerRpcParams rpcParams = default)
    {
        Camera.main.fieldOfView += zoom * zoomSpeed * Time.deltaTime;
        Camera.main.fieldOfView = Mathf.Clamp(Camera.main.fieldOfView, minZoom, maxZoom);
    }
}
