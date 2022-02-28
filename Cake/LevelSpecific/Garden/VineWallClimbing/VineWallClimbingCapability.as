import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Garden.VineWallClimbing.VineWall;

class UVineWallClimbingCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 10;

	UPROPERTY()
	UBlendSpace BS;

	AHazePlayerCharacter Player;

	bool bAttachToWall = false;

	AVineWall CurrentWall;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(CurrentWall == nullptr)
		 	return EHazeNetworkActivation::DontActivate;

		if (bAttachToWall)
			if(CurrentWall.WaterHoseComp.CurrentWaterLevel == 1.f || CurrentWall.IsWaterable == false)
        		return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(CurrentWall.WaterHoseComp.CurrentWaterLevel < 1.f && CurrentWall.IsWaterable == true)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.PlayBlendSpace(BS);
		Player.SmoothSetLocationAndRotation(Player.ActorLocation, CurrentWall.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.StopBlendSpace();
		bAttachToWall = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		FHitResult Hit;
		TArray<AActor> ActorsToIgnore;
		FVector StartLoc = Player.ActorLocation + FVector(0.f, 0.f, 100.f);
		FVector EndLoc = StartLoc + (Player.ActorForwardVector * 100.f);
		System::LineTraceSingle(StartLoc, EndLoc, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if (!Hit.bBlockingHit)
			return;

		AVineWall VineWall = Cast<AVineWall>(Hit.Actor);
		if (VineWall != nullptr)
		{
			CurrentWall = VineWall;
			bAttachToWall = true;
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	Print("Active");
		FVector Input = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		Player.SetBlendSpaceValues(Input.X, Input.Y);

		FVector MoveDir = (Player.ActorRightVector * Input.X) + (Player.ActorUpVector * Input.Y);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"VineWall");
		MoveData.ApplyDelta(MoveDir * 600.f * DeltaTime);
		MoveCharacter(MoveData, n"VineWall");
	}
}