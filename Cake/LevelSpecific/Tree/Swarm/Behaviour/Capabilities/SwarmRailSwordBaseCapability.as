

import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.Phase3RailSwordComponent;
import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackSwords;
import Cake.LevelSpecific.Tree.Swarm.Movement.SwarmTowardsVictimSlerper;

UCLASS(abstract)
class USwarmRailSwordBaseCapability: USwarmBehaviourCapability
{
	/* Arena middle transform + Desired offset */ 
	FTransform DesiredTransform = FTransform::Identity;

	float RandomOffsetFactor = 0.f;
	UPhase3RailSwordComponent ManagedSwarmComp;
	UQueenSpecialAttackSwords Manager;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(MoveComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if(MoveComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	FVector GetShieldOffset() const
	{
		return FVector::ZeroVector;
	}

	FVector GetSlaveShieldOffset() const
	{
		return FVector(
			ManagedSwarmComp.DesiredOffsetX,
			0.f,
			ManagedSwarmComp.DesiredOffsetZ
		);
	}

	USwarmTowardsVictimSlerper TowardsVictimSlerper;

	void UpdateDesiredTransform_RelativeToQueenAndVictim(const float Dt, const bool bTangentialToWorldPlane)
	{
		const UPrimitiveComponent QueenRoot = Cast<UPrimitiveComponent>(MoveComp.ArenaMiddleActor.GetRootComponent());
		const FVector Queen_COM = QueenRoot.GetCenterOfMass(); 

		TowardsVictimSlerper.UpdateTowardsVictimSlerper(Dt);

		// Calculate root-align bone offset. The offset will be rotated 
		// to be relative to the vector between the queen and the victim.
		const FQuat QueenToVictimQuat = Math::MakeQuatFromX(TowardsVictimSlerper.QueenToVictim);
		const FQuat SwarmToVictimQuat = TowardsVictimSlerper.SwarmToVictim.ToOrientationQuat();

		FVector DesiredOffset = FVector::ZeroVector;
		if (bTangentialToWorldPlane)
		{
			FQuat DummySwing, SwarmToVictimQuat_Twist, QueenToVictimQuat_Twist;
			SwarmToVictimQuat.ToSwingTwist( FVector::UpVector, DummySwing, SwarmToVictimQuat_Twist);
			QueenToVictimQuat.ToSwingTwist( FVector::UpVector, DummySwing, QueenToVictimQuat_Twist);
			DesiredTransform = FTransform(SwarmToVictimQuat_Twist, Queen_COM);
			DesiredOffset = QueenToVictimQuat_Twist.RotateVector(GetShieldOffset());
		}
		else
		{
			DesiredTransform = FTransform(SwarmToVictimQuat, Queen_COM);
			DesiredOffset = QueenToVictimQuat.RotateVector(GetShieldOffset());
		}

		if(!IsMasterShield())
		{
			DesiredOffset = GetShieldOffset() + GetSlaveShieldOffset();
			DesiredOffset = DesiredOffset.RotateAngleAxis(
				ManagedSwarmComp.CurrentAngle,
				// SwarmToVictimQuat.UpVector
				// QueenToVictimQuat.UpVector
				FVector::UpVector
			);
		}

		DesiredTransform.AddToTranslation(DesiredOffset);

		// We want the shields to the rotated outwards from the queen in YAW and ROLL.
		// but the shields should still PITCH downwards towards the player
		const FVector QueenToSwarm = Owner.GetActorLocation() - Queen_COM;
 		const FRotator QueenToSwarmRot = Math::MakeRotFromX(QueenToSwarm);
		// FRotator FinalRotation = DesiredTransform.GetRotation().Rotator();
		// FinalRotation.Yaw = QueenToSwarmRot.Yaw;
		// FinalRotation.Roll = QueenToSwarmRot.Roll;
		// DesiredTransform.SetRotation(FinalRotation);
		DesiredTransform.SetRotation(QueenToSwarmRot);

		// System::DrawDebugPoint(DesiredTransform.GetLocation(), 10.f, PointColor = FLinearColor::Yellow);
		// System::DrawDebugPoint(Queen_COM, 10.f, PointColor = FLinearColor::Blue);
	}

	bool IsMasterShield() const
	{
		return Manager.MasterShield == Owner;
	}

}