using UnityEngine;

public class PlayerController : MonoBehaviour
{


    [SerializeField]
    private float playerSpeed = 2.0f;

    [SerializeField]
    Transform cubeTransform; // Assign this in the inspector

    private Rigidbody rb;
    private float horizontalInput;
    private float verticalInput;

    // Position relative to the rotation of the cube
    public Vector3 cubeRelativePosition;

    private void Start()
    {
        rb = gameObject.GetComponent<Rigidbody>();
        cubeRelativePosition = cubeTransform.InverseTransformPoint(transform.position);
    }


    void Update()
    {
        // get input from player
        horizontalInput = Input.GetAxisRaw("Horizontal");
        verticalInput = Input.GetAxisRaw("Vertical");
    }

    void FixedUpdate()
    {

        // current position relative to the cube
        Vector3 currentPosition = cubeTransform.TransformPoint(cubeRelativePosition);


        // raycast from the player to the cube origin
        // the face it hits is the face that is facing the player
        RaycastHit hit;
        Vector3 rayDir = cubeTransform.position - currentPosition;
        Vector3 currentNormal = transform.up;
        if (Physics.Raycast(currentPosition, rayDir, out hit))
        {
            currentNormal = hit.normal;
        }

        // create a vector from the input, saturate it so that diagonal movement isn't faster
        Vector3 input = new Vector3(horizontalInput, verticalInput, 0);
        float inputSpeed = Mathf.Min(input.magnitude, 1.0f);

        // transform it from camera space to world space
        // this makes movement relative to the camera, which is more intuitive
        Vector3 moveDir = Camera.main.transform.TransformDirection(input).normalized;

        // project the move vector onto the plane of the face
        moveDir = Vector3.ProjectOnPlane(moveDir, currentNormal).normalized;

        Vector3 newPos = currentPosition + inputSpeed * playerSpeed * Time.fixedDeltaTime * moveDir;
        rb.MovePosition(newPos);

        // rotate the player to align with the face normal
        rb.MoveRotation(transform.rotation * Quaternion.FromToRotation(transform.up, currentNormal));

        // apply gravity
        rb.AddForce(Physics.gravity.magnitude * -currentNormal);

    }
}