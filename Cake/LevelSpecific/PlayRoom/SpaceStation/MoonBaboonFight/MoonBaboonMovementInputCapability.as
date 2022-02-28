import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonPathSpline;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonIntersectionPoint;
import Peanuts.Animation.Features.PlayRoom.MoonBaboonOnMoon;
import Vino.Movement.MovementSettings;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UMoonBaboonMovementInputCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MoonBaboonMovement");

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AMoonBaboonPathSpline CurrentPathSpline;
	AMoonBaboonPathSpline LastPathSpline;
	AMoonBaboonIntersectionPoint TargetIntersectionPoint;
	AMoonBaboonIntersectionPoint LastIntersectionPoint;

	ETimelineDirection DirectionAlongCurrentSpline;

	int TargetSplinePoint;

	float MovementSpeed = 1750.f;

	float CurrentForwardSpeed = 0.f;

	UPROPERTY()
	ULocomotionFeatureMoonBaboonOnMoon Feature;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"TargetIntersectionPoint") != nullptr)
        	return EHazeNetworkActivation::ActivateLocal;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UMovementSettings::SetMoveSpeed(Owner, MovementSpeed, Instigator = this);

		CurrentPathSpline = Cast<AMoonBaboonPathSpline>(GetAttributeObject(n"CurPathSpline"));
		DirectionAlongCurrentSpline = GetAttributeNumber(n"CurPathDirection") == 0 ? ETimelineDirection::Forward : ETimelineDirection::Backward;
		TargetIntersectionPoint = Cast<AMoonBaboonIntersectionPoint>(GetAttributeObject(n"TargetIntersectionPoint"));
		LastIntersectionPoint = TargetIntersectionPoint;

		Owner.PlaySlotAnimation(Animation = Feature.Run.Sequence, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.ClearSettingsByInstigator(Instigator = this);
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
		if (HasControl())
		{
			if (CurrentPathSpline == nullptr)
				return;

			FHazeFrameMovement FrameMoveData = MoveComp.MakeFrameMovement(n"FloorMove");
			FVector TargetLoc = CurrentPathSpline.Spline.GetLocationAtSplinePoint(TargetSplinePoint, ESplineCoordinateSpace::World) - Owner.ActorLocation;
			FVector Dir = Math::ConstrainVectorToPlane(TargetLoc, Owner.ActorUpVector);
			Dir = Dir.GetSafeNormal();
			MoveComp.SetTargetFacingDirection(Dir, 12.f);

			FVector MoveDelta = Dir * MoveComp.MoveSpeed * DeltaTime;

			if (MoveComp.IsAirborne())
			{
				float AirMoveSpeed = MoveComp.HorizontalAirSpeed;
				FrameMoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, Dir, AirMoveSpeed));
			}
			else
				FrameMoveData.ApplyDelta(MoveDelta);

			FrameMoveData.ApplyAndConsumeImpulses();
			FrameMoveData.ApplyTargetRotationDelta();
			FrameMoveData.FlagToMoveWithDownImpact();
			FrameMoveData.ApplyActorVerticalVelocity();
			FrameMoveData.ApplyGravityAcceleration();
			FrameMoveData.OverrideStepUpHeight(20.f);
			FrameMoveData.OverrideStepDownHeight(0.f);	

			MoveCharacter(FrameMoveData, n"Moon");

			if (TargetLoc.IsNearlyZero(100))
			{
				ChangeTargetSplinePoint();
			}

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Moon");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			FRotator TargetRot = ConsumedParams.Rotation;
			MoveComp.SetTargetFacingRotation(TargetRot);
			MoveData.ApplyTargetRotationDelta();

			MoveCharacter(MoveData, n"Moon");
		}
	}

	void ChangeTargetSplinePoint()
	{
		if (DirectionAlongCurrentSpline == ETimelineDirection::Forward)
			TargetSplinePoint ++;
		else
			TargetSplinePoint --;
		
		if (TargetSplinePoint > CurrentPathSpline.Spline.NumberOfSplinePoints || TargetSplinePoint < 0)
		{
			TArray<FMoonBaboonPathData> TempPathData = TargetIntersectionPoint.Paths;

			TempPathData.Shuffle();

			for (FMoonBaboonPathData CurData : TempPathData)
			{
				if (CurData.IntersectionPoint != LastIntersectionPoint)
				{
					LastIntersectionPoint = TargetIntersectionPoint;
					TargetIntersectionPoint = CurData.IntersectionPoint;
					DirectionAlongCurrentSpline = LastIntersectionPoint.GetDirectionToIntersectionPoint(CurData);
					CurrentPathSpline = CurData.Path;
					
					if (DirectionAlongCurrentSpline == ETimelineDirection::Forward)
						TargetSplinePoint = 1;
					else
						TargetSplinePoint = CurrentPathSpline.Spline.GetNumberOfSplinePoints() - 1;
					
					return;
				}
			}
		}
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