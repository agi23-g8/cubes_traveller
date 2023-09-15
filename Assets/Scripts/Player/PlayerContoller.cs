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

    private void Start()
    {
        rb = gameObject.GetComponent<Rigidbody>();
    }


    void Update()
    {
        // get input from player
        horizontalInput = Input.GetAxisRaw("Horizontal");
        verticalInput = Input.GetAxisRaw("Vertical");
    }

    void FixedUpdate()
    {
        // raycast from the player to the cube origin
        // the face it hits is the face that is facing the player
        RaycastHit hit;
        Vector3 rayDir = cubeTransform.position - transform.position;
        Vector3 currentNormal = transform.up;
        if (Physics.Raycast(transform.position, rayDir, out hit))
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

        // move the player relative to the parent (cube)
        Vector3 newPos = transform.position + moveDir * inputSpeed * playerSpeed * Time.fixedDeltaTime;
        rb.MovePosition(newPos);

        // apply gravity
        rb.AddForce(Physics.gravity.magnitude * -currentNormal);

        // rotate the player to align with the face normal
        rb.MoveRotation(Quaternion.FromToRotation(transform.up, currentNormal) * transform.rotation);
    }
}