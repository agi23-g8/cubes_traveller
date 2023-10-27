using UnityEngine;

[RequireComponent(typeof(Collider))]
public class SimpleInteraction : MonoBehaviour, IInteractable
{
    [SerializeField]
    private string interactionText;
    public string InteractionText => interactionText;

    [SerializeField]
    private GameObject tooltip;
    public GameObject UITooltip => tooltip;

    // connect this to the action you want to execute when the button is pressed
    public WorldAction ActionOnPressed;

    private void Start()
    {
        ToggleTooltip(false);
    }

    public bool OnInteract(Interactor interactor)
    {
        Debug.Log(interactionText);
        ActionOnPressed.Execute();
        return true;
    }

    public void OnTriggerEnter(Collider other)
    {
        ToggleTooltip(true);
    }

    public void OnTriggerExit(Collider other)
    {
        ToggleTooltip(false);
    }

    private void ToggleTooltip(bool show)
    {
        UITooltip.SetActive(show);
    }
}
