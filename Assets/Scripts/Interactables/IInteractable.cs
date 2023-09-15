using UnityEngine;

/// <summary>
/// Let objects use this interface to enable player interaction.
/// </summary>
public interface IInteractable
{
    /// <summary>
    /// Printed when OnInteract is called.
    /// </summary>
    public string InteractionText { get; }

    /// <summary>
    /// UI object that hints player
    /// </summary>
    public GameObject UITooltip { get; }

    /// <summary>
    /// Called when the player interacts with this object. 
    /// Here you can check conditions if the interaction should be successfull.
    /// </summary>
    /// <param name="interactor">Reference to player</param>
    /// <returns>true if the interaction was successfull</returns>
    public bool OnInteract(Interactor interactor);

    public void OnTriggerEnter(Collider other);

    public void OnTriggerExit(Collider other);
}
