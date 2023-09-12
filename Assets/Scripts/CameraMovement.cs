using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    private Vector2 touchStartPosition;
    private Vector2 touchEndPos;
    public float rotationSpeed = 10.0f;
    public Transform rotationAnchor;

    // Start is called before the first frame update
    void Start()
    {
        rotationAnchor = GameObject.Find("Cube").transform;
    }

    // Update is called once per frame

    void Update()
    {
        if (Input.touchCount == 1)
        {
            Touch touch = Input.GetTouch(0);

            switch (touch.phase)
            {
                case TouchPhase.Began:
                    touchStartPosition = touch.position;
                    break;

                case TouchPhase.Moved:
                    touchEndPos = touch.position;

                    Vector2 touchDelta = touchEndPos - touchStartPosition;

                    float rotationX = -touchDelta.y * rotationSpeed * Time.deltaTime;
                    float rotationY = touchDelta.x * rotationSpeed * Time.deltaTime;

                    // Turn the camera around the anchor
                    transform.RotateAround(rotationAnchor.position, Vector3.up, rotationY);
                    transform.RotateAround(rotationAnchor.position, Camera.main.transform.right, rotationX);

                    touchStartPosition = touch.position;
                    break;
            }
        }
    }
}
