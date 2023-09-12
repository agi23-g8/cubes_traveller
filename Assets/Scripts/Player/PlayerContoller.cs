using UnityEngine;

public class PlayerController : MonoBehaviour
{
    private Rigidbody rb;

    [SerializeField]
    private float playerSpeed = 2.0f;

    public Transform cubeTransform; // Assign this in the inspector

    private void Start()
    {
        rb = gameObject.GetComponent<Rigidbody>();
    }

    void Update()
    {
        float horizontalInput = Input.GetAxis("Horizontal");
        float verticalInput = Input.GetAxis("Vertical");

        Vector3 direction = new Vector3(horizontalInput, verticalInput, 0);
        Vector3 move = Camera.main.transform.TransformDirection(direction);

        // move the player along the projected direction
        rb.MovePosition(transform.position + move * playerSpeed * Time.deltaTime);
        if (move != Vector3.zero)
        {
            transform.rotation = Quaternion.LookRotation(move);
        }

        // raycast from the player to the cube origin
        // the face it hits is the face that is facing the player
        RaycastHit hit;
        Vector3 ray_dir = cubeTransform.position - transform.position;
        Vector3 normal_closest_face = Vector3.zero;
        if (Physics.Raycast(transform.position, ray_dir, out hit))
        {
            normal_closest_face = hit.normal;
        }

        // rotate player to such that players up vector aligns with the normal of the face
        transform.rotation = Quaternion.FromToRotation(transform.up, normal_closest_face) * transform.rotation;

        // tweak gravity so that the player remains bonded to the surface of the cube
        Physics.gravity = -normal_closest_face * Physics.gravity.magnitude;

    }
}