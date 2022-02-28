import Vino.Movement.Components.MovementComponent;
class USpeakerHoverCapability : UHazeCapability
{
	UPROPERTY()
	UBlendSpace CodyBS;

	UPROPERTY()
	UBlendSpace MayBS;

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	AHazePlayerCharacter Player;  
	FVector StartHoverPosition;
	UHazeBaseMovementComponent Movecomp;
	FQuat DesiredLookRotation;                                                            

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Movecomp = Player.MovementComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"SpeakerHover") && Movecomp.CanCalculateMovement())
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else                                                                       
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"SpeakerHover"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		if(IsActioning(n"Launchplayer"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DesiredLookRotation = Player.ActorRotation.Quaternion();
		if (Player.IsCody())
		{

			Player.PlayBlendSpace(CodyBS);
		}
		else
		{
			Player.PlayBlendSpace(MayBS);
		}
		
		Player.BlockCapabilities(n"Movement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopBlendSpace();
		Player.UnblockCapabilities(n"Movement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float MovementMultiplier = 100;
		FHazeFrameMovement Movement = Movecomp.MakeFrameMovement(n"Hover");
		
		float Alpha = DistanceToFloor * 0.0045f;
		Alpha = FMath::Clamp(Alpha, 0.f,1.f);
		Alpha = 1 - Alpha;
		MovementMultiplier = FMath::Lerp(0.f, 250.f, Alpha);
		FVector DesiredMoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (DesiredMoveDirection.Size() > 0)
		{
			DesiredLookRotation = FQuat::Slerp(DesiredLookRotation, FRotator::MakeFromX(DesiredMoveDirection).Quaternion(), DeltaTime * 2);
		}
		
		FVector MoveDelta = FVector::UpVector * MovementMultiplier * DeltaTime;
		MoveDelta += DesiredMoveDirection * 3;
		Movement.SetRotation(DesiredLookRotation);

		Movement.OverrideStepDownHeight(0);
		Movement.ApplyDelta(MoveDelta);
		Movecomp.Move(Movement);
	}

	float GetDistanceToFloor() property
	{
		FVector StartPos = Player.ActorLocation;
		FVector Endpos = Player.ActorLocation + FVector::UpVector * - 750;
		TArray<AActor> ActorsToIgnore;
		FHitResult HitResult;
		System::LineTraceSingle(StartPos,Endpos, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

		if (HitResult.bBlockingHit)
		{
			return HitResult.Location.Distance(Player.ActorLocation);
		}
		else
		{
			return -1;
		}
	}
}