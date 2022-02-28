import Cake.LevelSpecific.Garden.Vine.Vine;


class UGardenVinesCodyAnimInstance: UHazeAnimInstanceBase
{

	// Animations

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData RefPose;


	// Variables

	// SplineIK Control Point 1
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform SplineCtrlPointTop;

	// Rotation of the last joint in the chain
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator HeadRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector CtrlPointTop;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float VineAlpha;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float VineBendAlpha;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector VineSize;

	//UPROPERTY(BlueprintReadOnly, NotEditable)
	//FVector VineBaseSize;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EVineActiveType VineActiveType;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector TestScale;

	AVine Vine;
	FVector ControlPointTopOffset;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{

		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		Vine = Cast<AVine>(OwningActor);

		// Get the local offset for the ctrl point
		FTransform ControlPointTopOffsetTrasform;
		Animation::GetAnimBoneTransform(ControlPointTopOffsetTrasform, RefPose.Sequence, n"Vine36");
		ControlPointTopOffset = ControlPointTopOffsetTrasform.Location;
	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		// Valid check the actor
		if(Vine == nullptr)
			return;

		VineActiveType = Vine.VineActiveType;

		FTransform VineTargetTransform;
		VineTargetTransform.Location = Vine.GetCurrentLocation();
		FTransform VineBaseTransform = Vine.GetActorTransform();

		// We add a small offset so the mesh dont clip trough the impact mesh
		const float OffsetAmount = 80.f;
		FVector DirToBase = (VineBaseTransform.Location - VineTargetTransform.Location);
		if(DirToBase.SizeSquared() > FMath::Square(OffsetAmount))
			VineTargetTransform.Location = VineTargetTransform.Location  + (DirToBase.GetSafeNormal() * OffsetAmount);

		// Calculate the head rotation
		HeadRotation = FRotator::MakeFromZ(VineTargetTransform.Location - VineBaseTransform.Location);
		CtrlPointTop = VineTargetTransform.Location;

		float VineLength  = (VineTargetTransform.Location - VineBaseTransform.Location).Size();

		// Calculate spline top location
		FVector Offset = VineBaseTransform.Rotation.RotateVector(ControlPointTopOffset);
		VineBaseTransform.Location = VineBaseTransform.Location + Offset * VineBaseTransform.Scale3D;
		VineTargetTransform.SetToRelativeTransform(VineBaseTransform);
		SplineCtrlPointTop.Location = VineTargetTransform.Location;


		// Modify the the values that controls the Size based on distance. And the additive Alpha
		if(Vine.VineActiveType == EVineActiveType::Extending)
			VineAlpha = 1;
		else
			VineAlpha = FMath::Clamp(VineAlpha - DeltaTime * 5.f, 0.f, 1.f);

		// Add Bend to the Vine when its ActiveAndLocked
		if(Vine.VineActiveType == EVineActiveType::ActiveAndLocked)
			VineBendAlpha = FMath::Clamp(VineBendAlpha + DeltaTime, 0.f, 1.f);
		else
			VineBendAlpha = FMath::Clamp(VineBendAlpha - DeltaTime * 5.f, 0.f, 1.f);

		float VineLengthSize = Math::NormalizeToRange(VineLength, 500.f, 3000.f);
		VineLengthSize = FMath::Clamp(VineLengthSize, 0.f, 0.5f);
		VineLength = (VineLength - 200.f) / 400.f;
		VineLength = FMath::Clamp(VineLength, 0.f, 1.f) - VineLengthSize;		
		VineSize = FVector(VineLength);
		
	}	
}