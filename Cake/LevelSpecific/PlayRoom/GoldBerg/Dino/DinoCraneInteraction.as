import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneBouncePlatformComponent;


 class ADinocraneInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UInteractionComponent Interaction;
	default Interaction.ActivationSettings.ActivationTag = n"DinoCraneInteraction";

	default Interaction.FocusShape.Type = EHazeShapeType::None;
	default Interaction.ActionShape.Type = EHazeShapeType::Box;
	default Interaction.ActionShape.BoxExtends = FVector(1300.f, 900.f, 2000.f);
	default Interaction.ActionShapeTransform = FTransform(FVector(-500.f, 0.f, -1200.f));

	UPROPERTY()
	AActor PlatFormToBounceUp;

	UPROPERTY(DefaultComponent, Attach = Interaction)
	UBillboardComponent Billboard;
	default Billboard.RelativeScale3D = FVector(5.f);
	default Billboard.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = Interaction)
	USceneComponent DinoTargetPosition;

	AHazePlayerCharacter GrabbingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnActivated.AddUFunction(this, n"OnStartedInteraction");

		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"DinoFacingCondition");
		Interaction.AddTriggerCondition(n"DinoFacing", Condition);
	}

	UFUNCTION(BlueprintEvent)
	void OnStartedInteraction(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		auto RidingComp = UDinoCraneRidingComponent::Get(Player);
		auto DinoCrane = RidingComp.DinoCrane;
		GrabbingPlayer = Player;
		DinoCrane.StartBigDinoStomp();
		UDinoCraneBouncePlatformComponent BounceComponent = UDinoCraneBouncePlatformComponent::Get(PlatFormToBounceUp);
		BounceComponent.StartBounce();
	}

	UFUNCTION()
	bool DinoFacingCondition(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		auto RidingComp = UDinoCraneRidingComponent::Get(Player);
		if (RidingComp == nullptr)
			return false;

		auto DinoCrane = RidingComp.DinoCrane;
		if (DinoCrane == nullptr)
			return false;

		FVector DinoForward = DinoCrane.ActorForwardVector;
		FVector TowardsInteraction = (ActorLocation - DinoCrane.ActorLocation);
		TowardsInteraction.Z = 0.f;

		float FacingAngleDelta = DinoForward.AngularDistance(TowardsInteraction);
		if (FacingAngleDelta > 0.25f * PI)
			return false;

		return true;
	}
}