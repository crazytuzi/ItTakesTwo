import Vino.Interactions.InteractionComponent;
import Vino.LevelSpecific.Garden.ValveTurnInteractionLocomotionFeature;
import Vino.LevelSpecific.Garden.ValveTurnData;

event void FValveTurnInteractionFinishedSignature(AValveTurnInteractionActor Actor);
event void FValveTurnInteractionExitSignature(AValveTurnInteractionActor Actor, AHazePlayerCharacter Player);

enum EValveTurnInputType
{
	Rotating,
	LeftRight,
	UpDown
}

class AValveTurnInteractionActor : AHazeActor
{
	UPROPERTY(Category = "Valve")
	UValveTurnInteractionLocomotionFeature MayFeature;

	UPROPERTY(Category = "Valve")
	UValveTurnInteractionLocomotionFeature CodyFeature;

	UPROPERTY(Category = "Valve")
	EValveTurnInputType InputType = EValveTurnInputType::Rotating;

	// Which way is the correct input way
	UPROPERTY(Category = "Valve")
	bool bClockwiseIsCorrectInput = true;

	/* if true,
	 * when going over the endvalue, you will loop to the beginning
	 * when going over the startvalue, you will loop to the end
	 * this valve will never broadcast the 'OnTurnFinished' event 
	*/
	UPROPERTY(Category = "Valve")
	bool bLoopRotation = false;

	// How long you can turn the valve
	UPROPERTY(Category = "Valve")
	float MaxValue = 0;

	UPROPERTY(Category = "Valve")
	float IncreaseValueSpeed = 0;

	// This will make the worlds controlside control the interaction replication
	UPROPERTY(Category = "Valve")
	bool bUpdateValveFromWorldControl = false;

	// How fast you turn the valve when turning the wrong direction
	UPROPERTY(Category = "Valve")
	float DecreaseValueSpeed = 0;

	// How fast the valve turns back if you are not turning the correct direction
	UPROPERTY(Category = "Valve", meta = (EditCondition = "!bLoopRotation"))
	float AutoDecreaseValueSpeed = 0;

	UPROPERTY(Category = "Valve", meta = (EditCondition = "!bLoopRotation"))
	bool bForceEndOnFinsihed = true;

	UPROPERTY(Category = "Valve")
	bool bShowTutorialWidget = true;

	UPROPERTY(Category = "Valve", meta = (EditCondition="InputType == EValveTurnInputType::Rotating"))
	FText CW_TutorialDisplayText;

	UPROPERTY(Category = "Valve", meta = (EditCondition="InputType == EValveTurnInputType::Rotating"))
	FText CCW_TutorialDisplayText;

	UPROPERTY(Category = "Valve", meta = (EditCondition="InputType != EValveTurnInputType::Rotating"))
	FText Input_TutorialDisplayText;

	UPROPERTY(Category = "Valve")
	bool bUseCustomCancelText = false;

	UPROPERTY(Category = "Valve", meta = (EditCondition = "bUseCustomCancelText"))
	FText CustomCancelText;

	// Root
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// Enter interaction
	UPROPERTY(DefaultComponent, Attach = Rotator)
	UInteractionComponent EnterInteraction;
	default EnterInteraction.MovementSettings.InitializeDashTo();
	default EnterInteraction.ActionShape.Type = EHazeShapeType::Sphere;
	default EnterInteraction.ActionShape.SphereRadius = 0.f;
	default EnterInteraction.FocusShape.Type = EHazeShapeType::Box;
	default EnterInteraction.FocusShape.BoxExtends = FVector(150.f, 150.f, 100.f);
	default EnterInteraction.Visuals.VisualOffset.Location = FVector(65.f, 0.f, 167.420f);
	default EnterInteraction.RelativeLocation = FVector(100.f, 0.f, 0.f);
	default EnterInteraction.RelativeRotation = FRotator(0.f, 180.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = PushLeft)
	UBoxComponent EnterInteractionActionShape;
	default EnterInteractionActionShape.BoxExtent = FVector(150.f, 200.f, 200.f);
	default EnterInteractionActionShape.RelativeLocation = FVector(150.f, 0.f, 200.f);

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent ValveSkeletalMesh;
	default ValveSkeletalMesh.RelativeLocation = FVector(0.f, 0.f, 167.420f);

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncComponent;

	//Triggers when the players finalizes the interaction
	UPROPERTY(Category = "Events")
	FValveTurnInteractionFinishedSignature OnTurnFinished;

	//Triggers when player leaves the interaction 
	UPROPERTY(Category = "Events")
	FValveTurnInteractionExitSignature OnExit;

	EValveTurnInteractionAnimationDirection InputStatus = EValveTurnInteractionAnimationDirection::Unset;
	EValveTurnInteractionAnimationType PlayerStatus = EValveTurnInteractionAnimationType::None;
	float AnimationSpeed = 0;
	AHazePlayerCharacter CurrentActivePlayer;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapabilityClass;	

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		EnterInteraction.AddActionPrimitive(EnterInteractionActionShape);
		EnterInteraction.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		Capability::AddPlayerCapabilityRequest(n"ValveTurnInteractionCapability", EHazeSelectPlayer::Both);

		UClass AudioCapability = AudioCapabilityClass.Get();
		if(AudioCapability != nullptr)
			Capability::AddPlayerCapabilityRequest(AudioCapability, EHazeSelectPlayer::Both);
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        Capability::RemovePlayerCapabilityRequest(n"ValveTurnInteractionCapability", EHazeSelectPlayer::Both);
		Capability::RemovePlayerCapabilityRequest(n"ValveTurnInteractionAudioCapability", EHazeSelectPlayer::Both);
    }

	UFUNCTION(NotBlueprintCallable)
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		Player.SetCapabilityAttributeObject(n"ValveToTurn", this);	
		Player.SetCapabilityAttributeObject(n"AudioValveToTurn", this);
		EnterInteraction.Disable(n"PlayerIsInInteraction");
		if(bUpdateValveFromWorldControl)
			SyncComponent.OverrideControlSide(GetWorld());
		else
			SyncComponent.OverrideControlSide(Player);
		CurrentActivePlayer = Player;
    }

	UFUNCTION()
	void ForceEnd()
	{
		if(CurrentActivePlayer != nullptr)
		{
			CurrentActivePlayer.SetCapabilityActionState(n"ForceEndValveTurn", EHazeActionState::ActiveForOneFrame);
			CurrentActivePlayer.SetCapabilityActionState(n"AudioStoppedInteraction", EHazeActionState::ActiveForOneFrame);
		}
			
	}

	void EndInteraction(AHazePlayerCharacter Player)
	{
		EnterInteraction.EnableAfterFullSyncPoint(n"PlayerIsInInteraction");
		Player.SetCapabilityActionState(n"AudioStoppedInteraction", EHazeActionState::ActiveForOneFrame);
		PlayerStatus = EValveTurnInteractionAnimationType::None;
		InputStatus = EValveTurnInteractionAnimationDirection::Unset;
		AnimationSpeed = 0;
		OnExit.Broadcast(this, Player);
		CurrentActivePlayer = nullptr;
	}

	UFUNCTION(BlueprintPure)
	float GetSyncValue() const property
	{
		return SyncComponent.Value;
	}
}

