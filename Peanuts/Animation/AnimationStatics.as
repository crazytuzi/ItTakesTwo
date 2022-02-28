// -  -  ENUMS  -  -  //

enum EHazeBoolValueChangeWatcher
{
	BothWays,
	TrueToFalse,
	FalseToTrue,
}

UFUNCTION(BlueprintPure)
float GetVerticalAimSpaceValue(AHazePlayerCharacter OwningActor)
{
	return OwningActor.GetControlRotation().ForwardVector.DotProduct(OwningActor.GetMovementWorldUp());
}

UFUNCTION(BlueprintPure)
float GetHorizontalAimSpaceValue(AHazePlayerCharacter OwningActor)
{
	FRotator AimDeltaRotation = OwningActor.GetControlRotation() - OwningActor.GetActorRotation();
	AimDeltaRotation.Normalize();
	return AimDeltaRotation.Yaw / 180.f;
}

UFUNCTION(BlueprintPure)
FTransform GetIkBoneOffset(const FHazePlaySequenceData ReferenceAnimation, const float Time, const FName EffectorTargetBoneName = "Align", const FName TipBoneName = "None")
{
	// Get the Transform offset between two bones in the given animation at given time.
	FTransform ReferenceTransform;
	FTransform IKTransform;
	
	Animation::GetAnimBoneTransform(ReferenceTransform, ReferenceAnimation.Sequence, EffectorTargetBoneName, Time);
	Animation::GetAnimBoneTransform(IKTransform, ReferenceAnimation.Sequence, TipBoneName, Time);

	IKTransform.SetToRelativeTransform(ReferenceTransform);
	return IKTransform;
}

UFUNCTION(BlueprintPure)
FVector GetActorLocalVelocity(const AActor OwningActor) {
	// Get the velocity vector unrotated by the actor rotation.
	if(OwningActor != nullptr)
		return OwningActor.GetActorRotation().UnrotateVector(OwningActor.GetActorVelocity());
	else
		return FVector::ZeroVector;
}

UFUNCTION(BlueprintPure)
int RandomIntWithException(int Exception, int Min,  int Max){
	int ReturnValue = FMath::RandRange(Min, Max);
	if (ReturnValue == Exception)
		ReturnValue = Math::IWrap(ReturnValue + 1, Min, Max);
	return ReturnValue;
}

UFUNCTION(BlueprintPure)
float CircularBlendspaceInterpolation(float CurrentValue, float TargetValue, const float DeltaTimeX, const float MinAxisValue, float MaxAxisValue = 360.f, const float InterpSpeed = 5){
	// Interpolation for a 360 blendspace
	const float Span = MinAxisValue + MaxAxisValue;
	float NewTargetValue = TargetValue;
	if (FMath::Abs(CurrentValue - TargetValue) > Span / 2)
	{
		if (CurrentValue > TargetValue)
		{
			NewTargetValue += Span;
		}
		else
		{
			NewTargetValue -= Span;
		}
	}
	float InterpedValue = FMath::FInterpTo(CurrentValue, NewTargetValue, DeltaTimeX, InterpSpeed);
	return Math::FWrap(InterpedValue, MinAxisValue, MaxAxisValue);
}


UFUNCTION()
bool SetBooleanWithValueChangedWatcher(bool& CurrentValue, bool NewValue, EHazeBoolValueChangeWatcher TriggerDirection = EHazeBoolValueChangeWatcher::BothWays)
{
	const bool ReturnValue = (CurrentValue != NewValue);
	CurrentValue = NewValue;
	
	if(TriggerDirection == EHazeBoolValueChangeWatcher::BothWays)
	{
		return ReturnValue;
	}
	else if(TriggerDirection == EHazeBoolValueChangeWatcher::TrueToFalse && !CurrentValue)
	{
		return ReturnValue;
	}
	else if(TriggerDirection == EHazeBoolValueChangeWatcher::FalseToTrue && CurrentValue)
	{
		return ReturnValue;
	}
	return false;
}

// Grind aim values
UFUNCTION(BlueprintPure)
FVector2D ConvertGrindAimValues(FVector2D AimValues, AActor OwningActor, FRotator RootRotation)
{
	
	// Convert the 2D vector into a Rotator
	const FRotator AimRotation = FRotator(AimValues.Y, AimValues.X, 0.f);

	// Get the wanted aim direction in world space
	const FVector WorldSpaceAimDirection = (OwningActor.ActorRotation + AimRotation).Normalized.Vector();

	// Convert that aim direction to local space & make it a rotator
	FRotator LocalSpaceAim = Math::MakeRotFromXZ(RootRotation.UnrotateVector(WorldSpaceAimDirection), RootRotation.UpVector);

	return FVector2D(LocalSpaceAim.Yaw, LocalSpaceAim.Pitch);
}


//	-	-	-	-	-	-	//
//		Level Specific		//
//	-	-	-	-	-	-	//

//  -  -  SNOW GLOBE  -  -  //

// Swimming Pitch Rotation
UFUNCTION(BlueprintPure)
FRotator GetSwimmingRotationValue(AActor OwningActor, FRotator CurrentRotationValue, float DeltaTime, float InterpSpeed = 5)
{
	FVector Velocity = OwningActor.ActorVelocity;
	if (Velocity.Size() < 150.f) 
		return FRotator(FMath::FInterpTo(CurrentRotationValue.Pitch, 0, DeltaTime, InterpSpeed / 6.f), 0.f, 0.f);
	
	return FRotator(FMath::FInterpTo(CurrentRotationValue.Pitch, Velocity.Rotation().Pitch, DeltaTime, InterpSpeed), 0.f, 0.f);
}


// Wind direction for WindWalk
UFUNCTION(BlueprintPure)
float GetWindWalkBlendspaceDirection(AActor OwningActor, FVector WindForce)
{
	if (OwningActor == nullptr)
		return 0.0f;

	FRotator DeltaRotation = (WindForce.Rotation() - OwningActor.GetActorRotation());
	DeltaRotation.Normalize();

	if (DeltaRotation.Yaw < 0.f) 
		return DeltaRotation.Yaw + 360.f;
	
	return DeltaRotation.Yaw;
}







//
// 		Structs
//

// This should probably be rewritten in C++ later, only temorarily here for testing
/*
struct FHazePlayRandomLevelSequenceData
{
	UPROPERTY()
	TArray<ULevelSequence> Sequences;

	ULevelSequence GetRandomSequence()
	{
		const int NumberOfSequences = Sequences.Num();
		if (NumberOfSequences == 0)
			return nullptr;
		return Sequences[FMath::RandRange(0, NumberOfSequences) -1];
	}
}
*/