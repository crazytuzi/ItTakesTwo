
UCLASS(meta = ("World Camera Shake"))
class UAnimNotify_WorldCameraShakeAtBoneLocation : UAnimNotify 
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	FName BoneName = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	EHazeSelectPlayer AffectedPlayers = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	TSubclassOf<UCameraShakeBase> ShakeClass;

	// Relative offset from the attach component/point
	UPROPERTY(Category = "ForceFeedback")
	FVector LocationOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	EHazeWorldCameraShakeSamplePosition SamplePosition = EHazeWorldCameraShakeSamplePosition::Player;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	float InnerRadius = 0.f;

	/* Cameras outside of this radius do not get affected. */ 
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	float OuterRadius = 0.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	float Falloff = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	float Scale = 1.f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	bool bOrientShakeTowardsEpicenter = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	bool bDrawDebug = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	float DebugDuration = 1.f;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
 		return "World Camera Shake " + "(" + BoneName.ToString() + ")";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const 
	{
		if (MeshComp == nullptr)
			return false;

		if (!ShakeClass.IsValid())
			return false;

		if (AffectedPlayers == EHazeSelectPlayer::None)
			return false;

		FTransform BoneTransform = MeshComp.GetSocketTransform(BoneName);
//		const FVector BoneLocation = MeshComp.GetSocketLocation(BoneName);
		const FVector RotatedOffset = BoneTransform.GetRotation().RotateVector(LocationOffset);
		const FVector BoneLocation = BoneTransform.GetLocation() + RotatedOffset;

#if EDITOR
		if (bDrawDebug) 
		{
			System::DrawDebugSphere(
				BoneLocation,
				InnerRadius,
				LineColor = NotifyColor.ReinterpretAsLinear(),
				Duration = DebugDuration,
				Thickness = 10.f
			);

			System::DrawDebugSphere(
				BoneLocation,
				OuterRadius,
				LineColor = NotifyColor.ReinterpretAsLinear(),
				Duration = DebugDuration,
				Thickness = 10.f
			);
		}
#endif

		AHazePlayerCharacter May = Game::GetMay();
		AHazePlayerCharacter Cody = Game::GetCody();

		// early out if we're previewing animations
		if (May == nullptr && Cody == nullptr)
			return false;

#if EDITOR
		if (bDrawDebug) 
		{
			const float MayToCameraDistance = (May.GetActorCenterLocation() - May.GetPlayerViewLocation()).Size();
			const float CodyToCameraDistance = (Cody.GetActorCenterLocation() - Cody.GetPlayerViewLocation()).Size();
			Print("[" + GetName() + "] " + "May To Camera Distance: " + MayToCameraDistance, Duration = DebugDuration);
			Print("[" + GetName() + "] " + "Cody To Camera Distance: " + CodyToCameraDistance, Duration = DebugDuration);
		}
#endif

		if (AffectedPlayers == EHazeSelectPlayer::Both)
		{
			Cody.PlayWorldCameraShake(
				ShakeClass,
				BoneLocation,
				InnerRadius,
				OuterRadius,
				Falloff,
				Scale,
				bOrientShakeTowardsEpicenter,
				SamplePosition
			);
			May.PlayWorldCameraShake(
				ShakeClass,
				BoneLocation,
				InnerRadius,
				OuterRadius,
				Falloff,
				Scale,
				bOrientShakeTowardsEpicenter,
				SamplePosition
			);
			return true;
		}
		else if (AffectedPlayers == EHazeSelectPlayer::May)
		{
			May.PlayWorldCameraShake(
				ShakeClass,
				BoneLocation,
				InnerRadius,
				OuterRadius,
				Falloff,
				Scale,
				bOrientShakeTowardsEpicenter,
				SamplePosition
			);
			return true;
		}
		else if (AffectedPlayers == EHazeSelectPlayer::Cody)
		{
			Cody.PlayWorldCameraShake(
				ShakeClass,
				BoneLocation,
				InnerRadius,
				OuterRadius,
				Falloff,
				Scale,
				bOrientShakeTowardsEpicenter,
				SamplePosition
			);
			return true;
		}

		return false;

	}
};
