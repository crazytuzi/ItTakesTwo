import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrain;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;

class UCourtyardPlayerHogtiePlayerCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Camera;

	AHazePlayerCharacter Player;
	UInteractionComponent InteractionComp;
	ACourtyardTrain Train;
	UButtonMashProgressHandle ButtonMashHandle;

	float DistanceAlongSpline;
	FVector TrackLocation;

	bool bHogTied = false;

	UPROPERTY()
	TPerPlayer<UAnimSequence> HogtieVictimAnimation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	

		Train = Cast<ACourtyardTrain>(GetAttributeObject(n"Train"));

		InteractionComp = UInteractionComponent::Create(Player, NAME_None);
		InteractionComp.SetRelativeLocation(FVector(0.f, 0.f, 150.f));
		InteractionComp.DisableForPlayer(Player, n"DisabledForPlayer");
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionActivated(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		bHogTied = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Train = Cast<ACourtyardTrain>(GetAttributeObject(n"Train"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!bHogTied)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ButtonMashHandle.Progress < 1.f)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		InteractionComp.DisableForPlayer(Player.OtherPlayer, n"Active");
		
		bHogTied = true;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		DistanceAlongSpline = Train.Track.Spline.GetDistanceAlongSplineAtWorldLocation(Player.OtherPlayer.ActorLocation);
		TrackLocation = Train.Track.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		Owner.SetActorLocation(TrackLocation);

		FHazeSlotAnimSettings Settings;
		Settings.bLoop = true;
		Player.PlaySlotAnimation(HogtieVictimAnimation[Player], Settings);

		ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, Player.Mesh, NAME_None, FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		StopButtonMash(ButtonMashHandle);

		bHogTied = false;

		Player.StopAllSlotAnimations();

		InteractionComp.EnableForPlayer(Player.OtherPlayer, n"Active");

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ButtonMashHandle.Progress -= 0.25f * DeltaTime;
		ButtonMashHandle.Progress += ButtonMashHandle.MashRateControlSide * 0.075f * DeltaTime;
	}
}