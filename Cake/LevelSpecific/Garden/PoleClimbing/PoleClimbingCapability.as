import Cake.LevelSpecific.Garden.PoleClimbing.ClimbingPole;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.PoleClimbing.PoleClimbingComponent;
import Vino.Movement.MovementSystemTags;

class UPoleClimbingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 15;

	AHazePlayerCharacter Player;
	AClimbingPole CurrentPole;
	UHazeMovementComponent MoveComp;
	UPoleClimbingComponent PoleComp;

	bool bPoleClimbing = false;
	bool bOutOfBounds = false;
	bool bJumped = false;
	FVector CurrentPolePosition;
	FRotator CurrentPoleRotation;

	FVector CurrentPoleBounds;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
		PoleComp = UPoleClimbingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (bPoleClimbing)
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bOutOfBounds)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bJumped)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bJumped = false;
		bOutOfBounds = false;
		bPoleClimbing = false;

		Player.BlockCapabilities(CapabilityTags::Collision, this);

		Player.SmoothSetLocationAndRotation(CurrentPolePosition, CurrentPoleRotation);
		Player.MeshOffsetComponent.OffsetRelativeLocationWithSpeed(FVector(-25.f, 0.f, 0.f));
		Player.MeshOffsetComponent.OffsetRelativeRotationWithSpeed(FRotator(90.f, 0.f, 0.f));

		Player.PlayBlendSpace(PoleComp.ClimbingBS);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		
		Player.SmoothSetLocationAndRotation(Player.ActorLocation - (CurrentPoleRotation.Vector() * 100.f), Player.ActorRotation);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		Player.MeshOffsetComponent.ResetLocationWithTime(0.f);
		Player.MeshOffsetComponent.ResetRotationWithTime(0.f);

		Player.StopBlendSpace();

		if (bJumped)
		{
			FVector LaunchForce = CurrentPoleRotation.Vector() * -1000.f;
			LaunchForce += FVector(0.f, 0.f, 2000.f);
			Player.AddImpulse(LaunchForce);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		FHitResult ForwardHit = MoveComp.ForwardHit;

		if (ForwardHit.bBlockingHit && ForwardHit.Actor != nullptr)
		{
			AClimbingPole Pole = Cast<AClimbingPole>(ForwardHit.Actor);
			if (Pole != nullptr)
			{
				CurrentPolePosition = Pole.ActorLocation;
				CurrentPolePosition.Z = Player.ActorLocation.Z;
				FVector DirToPole = Pole.ActorLocation - Player.ActorLocation;
				DirToPole.Normalize();
				DirToPole = Math::ConstrainVectorToPlane(DirToPole, FVector::UpVector);
				CurrentPoleRotation = DirToPole.Rotation();
				CurrentPole = Pole;
				bPoleClimbing = true;
			}
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		CurrentPoleRotation.Yaw += -Input.X * 150.f * DeltaTime;
		MoveComp.SetTargetFacingRotation(CurrentPoleRotation);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"PoleClimbing");
		MoveData.ApplyDelta(FVector(0.f, 0.f, Input.Y * 600.f * DeltaTime));
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.ApplyTargetRotationDelta();
		MoveComp.Move(MoveData);

		FVector BoundsOrigin;
		FVector BoundsExtent;
		CurrentPole.GetActorBounds(false, BoundsOrigin, BoundsExtent);

		float BottomPos = BoundsOrigin.Z - BoundsExtent.Z;
		float TopPos = BoundsOrigin.Z + BoundsExtent.Z;
		float PlayerPos = Player.ActorLocation.Z;

		if (PlayerPos <= BottomPos || PlayerPos >= TopPos)
			bOutOfBounds = true;

		if (WasActionStarted(ActionNames::MovementJump))
			bJumped = true;
	}
}