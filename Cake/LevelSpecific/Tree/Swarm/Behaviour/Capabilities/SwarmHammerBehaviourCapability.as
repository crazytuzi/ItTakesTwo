
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

// Common hammer capability library
UCLASS(Abstract)
class USwarmHammerBehaviourCapability : USwarmBehaviourCapability
{
	default CapabilityTags.Add(n"SwarmHammer");

	void UpdateMovement_TelegraphInit(const float Dt)
	{
		//UpdateMovement_TelegraphInit_OLD(Dt);
		// return;

		const FTransform VictimTransform = VictimComp.GetLastValidGroundTransform();
		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsActor(VictimComp.PlayerVictim);

		const FVector ArenaMidPos = MoveComp.ArenaMiddleActor.GetActorLocation();

		// System::DrawDebugSphere(
		// ArenaMidPos,
		// 100.f, 8.f, FLinearColor::Red , 0.f);

		const FVector VictimCenterPos = VictimComp.GetVictimCenterTransform().GetLocation();
		const FVector TowardsTarget = VictimCenterPos - ArenaMidPos;
		const FQuat QueenToVictimQuat = TowardsTarget.ToOrientationQuat();

		// We'll just use WorldUp because the groundnormal might sometimes 
		// return almost horizontal normals when the player is walking on bump ground.
		const FVector GroundNormal = FVector::UpVector;
		// const FVector GroundNormal = VictimComp.GetVictimGroundNormal();

		FQuat DummySwing, SwarmToVictimQuat_Twist, QueenToVictimQuat_Twist;

		// Swarm To Victim Quat projected on plane that the player is standing on.
		SwarmToVictimQuat.ToSwingTwist(
			GroundNormal,
			DummySwing,
			SwarmToVictimQuat_Twist
		);

		// Queen to victim quat projected on the plane that the player is standing on 
		QueenToVictimQuat.ToSwingTwist(
			GroundNormal,
			DummySwing,
			QueenToVictimQuat_Twist
		);

		// System::DrawDebugLine(
		// 	VictimTransform.GetLocation(),
		// 	VictimTransform.GetLocation() - QueenToVictimQuat_Twist.Vector()*10000.f,
		// 	FLinearColor::Yellow,
		// 	0.f,
		// 	6.f
		// );

		CalculateDesiredQuatWhileGentlemaning(QueenToVictimQuat_Twist);

		// System::DrawDebugLine(
		// 	VictimTransform.GetLocation(),
		// 	VictimTransform.GetLocation() - QueenToVictimQuat_Twist.Vector()*10000.f,
		// 	FLinearColor::Red,
		// 	0.f,
		// 	6.f
		// );

		// The offset will be relative to the vector between the Queen and the victim
		// but the vector will be projected on the ground plane that the player is standing on.
 		const FVector AlignOffset = QueenToVictimQuat_Twist.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
		const FVector ExtraOffset = QueenToVictimQuat_Twist.RotateVector(
			Settings.Hammer.TelegraphInitial.AdditionalOffset
		);

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			VictimTransform.GetLocation() - AlignOffset + ExtraOffset
		);

		MoveComp.InterpolateToTargetLocation(
			DesiredTransform.GetLocation(),
			Settings.Hammer.TelegraphInitial.LerpTowardsMiddleSpeed,
			Settings.Hammer.TelegraphInitial.bInterpConstantSpeed,
			Dt	
		);

		// face the player we are going to attack 
		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			// MoveComp.GetFacingRotationTowardsLocation(VictimComp.GetLastValidGroundLocation()),
			Settings.Hammer.TelegraphInitial.RotateTowardsPlayerSpeed,
			Settings.Hammer.TelegraphInitial.bInterpConstantSpeed,
			Dt	
		);

		// System::DrawDebugSphere(
		// MoveComp.DesiredSwarmActorTransform.GetLocation(),
		// 100.f, 8.f,
		// FLinearColor::Blue
		// , 0.f
		// );

	}

	void UpdateMovement_TelegraphInit_OLD(const float Dt)
	{
		// Additional offset rotate by the middle actors YAW rotation.
		FQuat Swing, Twist;
		const FQuat ArenaMidRot = SwarmActor.MovementComp.ArenaMiddleActor.GetActorQuat();
		ArenaMidRot.ToSwingTwist(FVector::UpVector, Swing, Twist);
		const FVector RotatedOffset = Twist.RotateVector(Settings.Hammer.TelegraphInitial.AdditionalOffset);

		// got to middle + additional offset
		MoveComp.InterpolateToTargetLocation(
 			MoveComp.ArenaMiddleActor.GetActorTransform().GetLocation() + RotatedOffset,
			Settings.Hammer.TelegraphInitial.LerpTowardsMiddleSpeed,
			Settings.Hammer.TelegraphInitial.bInterpConstantSpeed,
			Dt	
		);

		// face the player we are going to attack 
		MoveComp.InterpolateToTargetRotation(
			MoveComp.GetFacingRotationTowardsLocation(VictimComp.GetLastValidGroundLocation()),
			Settings.Hammer.TelegraphInitial.RotateTowardsPlayerSpeed,
			Settings.Hammer.TelegraphInitial.bInterpConstantSpeed,
			Dt	
		);
	}

}