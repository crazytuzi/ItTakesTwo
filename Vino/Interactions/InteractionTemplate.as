import Vino.Interactions.InteractionComponent;

class AInteractionTemplate : AHazeActor
{
    UPROPERTY(DefaultComponent, Attach = RootComp)
    UInteractionComponent InteractionPoint;

	default InteractionPoint.MovementSettings.InitializeSmoothTeleport();
	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 350.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.FocusShape.SphereRadius = 1000.f;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");
    }

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		Print("Interaction point was used by "+Player);
    }
}