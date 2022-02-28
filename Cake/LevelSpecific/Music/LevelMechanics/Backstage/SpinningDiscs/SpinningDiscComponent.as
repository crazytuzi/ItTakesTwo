class USpinningdiscComponent : UActorComponent
{
	UPROPERTY()
	FHazeTimeLike TimeLike;

	UPROPERTY()
	bool bReverse;

	default TimeLike.bLoop = true;
	default TimeLike.bSyncOverNetwork = true;
	default TimeLike.Duration = 1;

	// Eman present: Owner can be null here, move to BeginPlay?
	// default TimeLike.SyncTag = FName(Owner.Name + Owner.ActorLocation.Z);

	float StartRot;

	UPROPERTY()
	bool bStartDisabled = false;

	UPROPERTY()
	bool bUseRoll = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeLike.BindUpdate(this, n"UpdateTimeLike");

		if (bUseRoll)
		{
			StartRot = Owner.ActorRotation.Roll;
		}

		else
		{
			StartRot = Owner.ActorRotation.Yaw;
		}
		
		if (!bStartDisabled)
		{
			PlayTimelike();
		}
	}

	UFUNCTION()
	void PlayTimelike()
	{
		if (bReverse)
		{
			TimeLike.Reverse();
		}
		else
		{
			TimeLike.Play();
		}
	}

	UFUNCTION()
	void UpdateTimeLike(float Duration)
	{
		float Rot = 360 * Duration;
		FRotator Rotation = Owner.ActorRotation;



		if (bUseRoll)
		{
			Rotation.Roll = Rot + StartRot;
		}
		else
		{
			Rotation.Yaw = Rot + StartRot;
		}

		Rotation = FQuat::Slerp(Owner.RootComponent.RelativeRotation.Quaternion(), Rotation.Quaternion(), Owner.ActorDeltaSeconds * 2.f).Rotator();
		
		FHitResult HitResult;
		Owner.SetActorRelativeRotation(Rotation, false, HitResult, false);
	}
}