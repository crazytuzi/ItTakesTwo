import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Hopscotch.BallFallStatics;

event void EBallFallValveSignature(EValveColor ValveColor);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class ABallFallValve : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY()
	EValveColor ValveColor;

	UPROPERTY()
	FHazeTimeLike RotateValveTimeline;
	default RotateValveTimeline.Duration = 1.f;

	UPROPERTY()
	EBallFallValveSignature ValveActivatedEvent;

	UPROPERTY()
	UAnimSequence CodyPushAnim;
	
	UPROPERTY()
	UAnimSequence MayPushAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionCompActivated");
		
		RotateValveTimeline.BindUpdate(this, n"RotateValveTimelineUpdate");
	}

	UFUNCTION()
	void InteractionCompActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		ValveActivatedEvent.Broadcast(ValveColor);
		Comp.Disable(n"HasBeenUsed");

		UAnimSequence AnimToPlay = Player == Game::GetCody() ? CodyPushAnim : MayPushAnim;

		Player.PlayEventAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay);

		RotateValveTimeline.PlayFromStart();
	}

	UFUNCTION()
	void RotateValveTimelineUpdate(float CurrentValue)
	{
		MeshRoot.AddLocalRotation(FRotator(CurrentValue * 10.f, 0.f, 0.f));
	}
}