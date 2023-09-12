using UnityEngine;

/// <summary>
/// Enables the player to interact with game objects that use the IInteractable interface.
/// </summary>
public class PlayerInteractor : MonoBehaviour
{
    /// <summary>
    /// Max num of interactables that can be in range at once. Should really only be atm 1.
    /// </summary>
    public const int MAX_INTERACTABLES = 4;

    [SerializeField]
    [Range(0.1f, 1.0f)]
    private float searchRange;

    [SerializeField] 
    private LayerMask mask;

    private Collider[] results = new Collider[MAX_INTERACTABLES];
    private int numInRange = 0;

    private void Update()
    {
        numInRange = Physics.OverlapSphereNonAlloc(
            transform.position,
            searchRange,
            results,
            mask
        );

        if (numInRange < 1)
        {
            return;
        }
            

        var interactable = results[0].GetComponent<IInteractable>();
        if (interactable == null)
        {
            return;
        }

        // TODO: Display UI with InteractionText

        // TODO: Checkout Unity's new Input System!
        if (Input.GetKeyDown(KeyCode.E))
        {
            interactable.OnInteract(this);
        }
            
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.DrawWireSphere(transform.position, searchRange);
    }
}
