
class URelativeBoneCrumbLocationCalculator : UHazeReplicationLocationCalculator
{
	AHazeActor HazeOwner;
	UPrimitiveComponent RelativeComponent;

	FQuat TargetRotation;
	FRotator CurrentRotation;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor inOwner, USceneComponent inRelativeComponent)
	{
		HazeOwner = inOwner;
		RelativeComponent = Cast<UPrimitiveComponent>(inRelativeComponent);
	}

	bool HasBone(FName SocketName) const
	{
		if (SocketName == NAME_None)
			return false;

		return RelativeComponent.DoesSocketExist(SocketName);
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		if (RelativeComponent == nullptr)
			return;

		FVector WorldLoc = HazeOwner.ActorLocation;
		FQuat WorldRot = HazeOwner.ActorQuat;

		FTransform RelativeTo = RelativeComponent.WorldTransform;
		if (HasBone(OutTargetParams.FollowBone))
			RelativeTo = RelativeComponent.GetSocketTransform(OutTargetParams.FollowBone);

		OutTargetParams.Location = RelativeTo.InverseTransformPosition(WorldLoc);
		OutTargetParams.Rotation = (RelativeTo.Rotation.Inverse() * WorldRot).Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{
		if (RelativeComponent == nullptr)
			return;

		TargetRotation = TargetParams.Rotation.Quaternion();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{
		if (RelativeComponent ==  nullptr)
			return;

		FTransform RelativeTo = RelativeComponent.WorldTransform;
		if (HasBone(CurrentParams.FollowBone))
			RelativeTo = RelativeComponent.GetSocketTransform(CurrentParams.FollowBone);

		FQuat WorldRot = RelativeTo.Rotation * TargetRotation;

		CurrentRotation = FMath::QInterpTo(CurrentParams.Rotation.Quaternion(), WorldRot, DeltaTime, 9.f).Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		if (RelativeComponent == nullptr)
			return;

		FVector RelLoc = TargetParams.Location;

		FTransform RelativeTo = RelativeComponent.WorldTransform;
		if (HasBone(TargetParams.FollowBone))
			RelativeTo = RelativeComponent.GetSocketTransform(TargetParams.FollowBone);

		FVector WorldLoc = RelativeTo.TransformPosition(RelLoc);

		TargetParams.Location = WorldLoc;
		TargetParams.Rotation = CurrentRotation;
	}
}
