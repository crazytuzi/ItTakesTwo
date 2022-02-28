import Cake.LevelSpecific.Hopscotch.SpawnableTunnel;

class UMoveThroughTunnelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MoveThroughTunnelCapability");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"MoveThroughTunnelCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
    ASpawnableTunnel Tunnel;
    UHazeSplineComponent Spline;
    float Distance;
    float MovementSpeed = 7000.f;

	UPROPERTY()
	UAnimSequence CodyAnim;
	
	UPROPERTY()
	UAnimSequence MayAnim;

	UHazeBaseMovementComponent MoveComp;

	FHazePointOfInterest PointOfInterest;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeBaseMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(IsActioning(n"InsideTunnel"))
        {
            return EHazeNetworkActivation::ActivateLocal;
        }
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"InsideTunnel"))
        {
            return EHazeNetworkDeactivation::DeactivateLocal;
        }
        else
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		Spline = Cast<UHazeSplineComponent>(GetAttributeObject(n"TunnelSpline"));
        Distance = 0;

		Player.BlockCapabilities(n"Movement", this);
		Player.BlockMovementSyncronization(this);

		UAnimSequence AnimToPlay = Player == Game::GetCody() ? CodyAnim : MayAnim;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay, true);
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
		Player.ClearPivotOffsetByInstigator(this);

		Player.StopAllSlotAnimations();
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockMovementSyncronization(this);
		Player.SetCapabilityActionState(n"InsideTunnel", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MovePlayer();
		
		if (IsBlocked())
			return;

		SetCameraPointOfInterest();
		
		Distance += MovementSpeed * Player.ActorDeltaSeconds;

        if (Distance >= Spline.GetSplineLength())
        {
            Player.SetCapabilityActionState(n"InsideTunnel", EHazeActionState::Inactive);
			ExitedTunnel();
        }
	}

	void MovePlayer()
	{
		FVector NewLocation = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
		MoveComp.SetControlledComponentTransform(NewLocation, Player.ActorRotation);			
	}

	void SetCameraPointOfInterest()
	{
		FVector NewPointOfInterestLocation = Spline.GetLocationAtDistanceAlongSpline(Distance + 500.f, ESplineCoordinateSpace::World);
		PointOfInterest.FocusTarget.WorldOffset = NewPointOfInterestLocation;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterest.Blend.BlendTime = 0.f;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.f;
		Player.ApplyPivotOffset(FVector::ZeroVector, Blend, this);
		Player.ApplyCameraOffsetOwnerSpace(FVector::ZeroVector, Blend, this);

		Player.ApplyPointOfInterest(PointOfInterest, this);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void ExitedTunnel()
	{
		// Doing this in BP!
	}
	

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}