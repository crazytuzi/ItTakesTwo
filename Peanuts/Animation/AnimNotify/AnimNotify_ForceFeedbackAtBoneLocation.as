
UCLASS(HideCategories = "Category", meta = ("World ForceFeedback"))
class UAnimNotify_ForceFeedbackAtBoneLocation : UAnimNotifyState 
{
	// Settings that will define the volume in which the forcefeedback is active
	UPROPERTY(Category = ForceFeedback,  meta = (ShowOnlyInnerProperties))
	FForceFeedbackAttenuationSettings AttenuationSettings;

	// socket location
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	FName BoneName = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "AnimNotify")
	EHazeSelectPlayer AffectedPlayers = EHazeSelectPlayer::Both;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect ForceFeedbackEffect;

	/* 
		whether to stop playing the forcefeedback if its duration 
	 	exceeds the animnotify state length or allow it to finish.

		Looping forcefeedbacks will be set to false at NotifyEnd, 
		allowing it to do one last rumble before it dies.
	*/
	UPROPERTY(Category = "ForceFeedback")
	bool bAllowForceFeedbackToFinishAtNotifyEnd = true;

	/* whether to loop the forcefeedback once it is done,
		allowing it to rumble throughout the entire animnotify duration */
	UPROPERTY(Category = "ForceFeedback")
	bool bLooping = true;

	/* will be multipled with the end result. */
	UPROPERTY(Category = "ForceFeedback")
	float IntensityMultiplier = 1.f;

	// Relative offset from the attach component/point
	UPROPERTY(Category = "ForceFeedback")
	FVector LocationOffset = FVector::ZeroVector;

	UPROPERTY(Category = "ForceFeedback")
	FRotator RotationOffset = FRotator::ZeroRotator;

	// How far in to the feedback effect to begin playback at
	UPROPERTY(Category = "ForceFeedback")
	float StartTime = 0.f;

	/* Whether the returned force feedback component will be automatically cleaned up when the 
	 feedback pattern finishes (by completing or stopping) or whether it can be reactivated */
	UPROPERTY(Category = "ForceFeedback")
	bool bAutoDestroy = false;

	// /* Whether we allow the forcefeedback to finish 
	// 	when the owner gets destroyed or disabled. */
	// UPROPERTY(Category = "ForceFeedback")
	// bool bStopWhenAttachedToDestroyed = false;

	UPROPERTY(Category = "ForceFeedback")
	bool bDrawDebug = true;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
 		return "World ForceFeedback " + "(" + BoneName.ToString() + ")";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration) const
	{
		UForceFeedbackComponent FFC = nullptr;
		UForceFeedbackComponent FoundFFC = FindOurForceFeedbackComponent(MeshComp);
		if(FoundFFC != nullptr)
		{
			FFC = FoundFFC;
			UpdateForceFeedbackComponent(FFC);
			FFC.Play(StartTime);
		}
		else
		{
			FFC = Gameplay::SpawnForceFeedbackAttached(
				ForceFeedbackEffect,
				MeshComp,
				BoneName,
				LocationOffset,
				RotationOffset,
				EAttachLocation::SnapToTargetIncludingScale,
				false,	// bStopWhenAttachedToDestroyed
				false,	// bLooping, (we loop it ourselves on tick because NotifyEnd isn't reliable)
				IntensityMultiplier,
				StartTime,
				nullptr,
				bAutoDestroy
			);

			if(FFC != nullptr)
				FFC.AdjustAttenuation(AttenuationSettings);
		}

		if(FFC == nullptr)
			return false;

		ensure(FFC.bLooping == false);

		// TArray<USceneComponent> ChildComps;
		// MeshComp.GetChildrenComponents(false, ChildComps);
		// PrintToScreen("The FFC: " + FFC.GetName());
		// PrintToScreen("num FFCs: " + ChildComps.Num(), Duration = 1.f);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyTick(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float FrameDeltaTime) const
	{
		UForceFeedbackComponent FFC = FindOurForceFeedbackComponent(MeshComp);

		if(FFC == nullptr)
			return false;

#if EDITOR
		const bool bPreviewing = GetWorld().IsEditorWorld();
		if(bPreviewing)
			UpdateForceFeedbackComponent(FFC);

		if(bDrawDebug)
			UpdateDrawDebug(FFC);
#endif

		if(bLooping && !FFC.IsActive())
		{
			UpdateForceFeedbackComponent(FFC);
			FFC.Play(StartTime);
			// PrintToScreen("looping FCC: " + FFC.ForceFeedbackEffect.GetName(), Duration = 2.f);
		}

		// ensure(FFC.bLooping == false);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		UForceFeedbackComponent FFC = FindOurForceFeedbackComponent(MeshComp);

		// PrintToScreen("Stopping FCC: " + FFC.ForceFeedbackEffect.GetName(), Duration = 2.f);

		if(FFC == nullptr)
		{
			// devEnsure(false, "Forcefeedback wasn't found. This might cause it to rumble forever! \n Please let sydney know if this triggers");

			// Hmm was it not found... Please let Sydney know about this.
			ensure(false);
			return false;
		}

		// ensure(FFC.bLooping == false);

		FFC.bLooping = false;
		if(!bAllowForceFeedbackToFinishAtNotifyEnd)
			FFC.Stop();

		return true;
	}

	void UpdateForceFeedbackComponent(UForceFeedbackComponent InFFC) const
	{
		// Apply same settings as when we Spawn it, in case something has changed it.
		InFFC.SetRelativeLocationAndRotation(LocationOffset, RotationOffset);
		InFFC.IntensityMultiplier = IntensityMultiplier;

		// we loop it ourselves on tick because NotifyEnd isn't reliable
		InFFC.bLooping = false;
		// InFFC.bLooping = bLooping;

		InFFC.AdjustAttenuation(AttenuationSettings);
	}

	UForceFeedbackComponent FindOurForceFeedbackComponent(USkeletalMeshComponent MeshComp) const
	{
		// try to reuse a previous one.
		TArray<USceneComponent> ChildComps;
		MeshComp.GetChildrenComponents(false, ChildComps);
		for (int i = ChildComps.Num() - 1; i >= 0; i--)
		{
			UForceFeedbackComponent FFC = Cast<UForceFeedbackComponent>(ChildComps[i]);
			if(FFC != nullptr)
			{
				if(FFC.ForceFeedbackEffect == ForceFeedbackEffect && FFC.GetAttachSocketName() == BoneName)
				{
					return FFC;
				}
			}
		}

		return nullptr;
	}

#if EDITOR
	void UpdateDrawDebug(UForceFeedbackComponent InForceFeedbackComp) const
	{
		// if(GetWorld().IsEditorWorld())
		if(bDrawDebug)
		{
			switch (AttenuationSettings.AttenuationShape)
			{
				case EAttenuationShape::Box:
					DrawBox(InForceFeedbackComp);
					break;
				case EAttenuationShape::Capsule:
					DrawCapsule(InForceFeedbackComp);
					break;
				case EAttenuationShape::Cone:
					DrawCone(InForceFeedbackComp);
					break;
				case EAttenuationShape::Sphere:
					DrawSphere(InForceFeedbackComp);
					break;
				default:
					DrawSphere(InForceFeedbackComp);
			}
		}
	}

	void DrawBox(UForceFeedbackComponent InForceFeedbackComp) const
	{
		const FTransform FinalTransform = InForceFeedbackComp.GetWorldTransform();
		const FVector Extents = AttenuationSettings.AttenuationShapeExtents;

		System::DrawDebugBox(
			FinalTransform.GetLocation(),
			Extents,
			NotifyColor.ReinterpretAsLinear(),
			FinalTransform.GetRotation().Rotator(),
			0.f,
			10.f
		);

		System::DrawDebugBox(
			FinalTransform.GetLocation(),
			Extents+AttenuationSettings.FalloffDistance,
			NotifyColor.ReinterpretAsLinear(),
			FinalTransform.GetRotation().Rotator(),
			0.f,
			10.f
		);
	}

	void DrawCapsule(UForceFeedbackComponent InForceFeedbackComp) const
	{
		FForceFeedbackAttenuationSettings CurrentAttenuationSettings;
		InForceFeedbackComp.GetAttenuationSettingsToApply(CurrentAttenuationSettings);

		const FTransform FinalTransform = InForceFeedbackComp.GetWorldTransform();
		const FVector Extents = CurrentAttenuationSettings.AttenuationShapeExtents;

		System::DrawDebugCapsule(
			FinalTransform.GetLocation(),
			CurrentAttenuationSettings.AttenuationShapeExtents.X,
			CurrentAttenuationSettings.AttenuationShapeExtents.Y,
			FinalTransform.GetRotation().Rotator(),
			NotifyColor.ReinterpretAsLinear(),
			0.f,
			10.f
		);

		System::DrawDebugCapsule(
			FinalTransform.GetLocation(),
			CurrentAttenuationSettings.AttenuationShapeExtents.X + CurrentAttenuationSettings.FalloffDistance,
			CurrentAttenuationSettings.AttenuationShapeExtents.Y + CurrentAttenuationSettings.FalloffDistance,
			FinalTransform.GetRotation().Rotator(),
			NotifyColor.ReinterpretAsLinear(),
			0.f,
			10.f
		);

	}

	void DrawCone(UForceFeedbackComponent InForceFeedbackComp) const
	{
		FForceFeedbackAttenuationSettings CurrentAttenuationSettings;
		InForceFeedbackComp.GetAttenuationSettingsToApply(CurrentAttenuationSettings);

		FTransform FinalTransform = InForceFeedbackComp.GetWorldTransform();
		FinalTransform.SetScale3D(FVector::OneVector);
		const FVector Direction = FinalTransform.GetRotation().Vector();
		FinalTransform.AddToTranslation(Direction * CurrentAttenuationSettings.ConeOffset * -1.f);

		float ConeRadius = CurrentAttenuationSettings.AttenuationShapeExtents.X + CurrentAttenuationSettings.FalloffDistance + CurrentAttenuationSettings.ConeOffset;
		float ConeAngle = CurrentAttenuationSettings.AttenuationShapeExtents.Y + CurrentAttenuationSettings.AttenuationShapeExtents.Z;

		System::DrawDebugConeInDegrees(
			FinalTransform.GetLocation(),
			Direction,
			ConeRadius,
			ConeAngle,
			ConeAngle,
			12,
			NotifyColor.ReinterpretAsLinear(),
			0.f,
			10.f
		);

		ConeRadius = CurrentAttenuationSettings.AttenuationShapeExtents.X + CurrentAttenuationSettings.ConeOffset;
		ConeAngle = CurrentAttenuationSettings.AttenuationShapeExtents.Y;

		System::DrawDebugConeInDegrees(
			FinalTransform.GetLocation(),
			Direction,
			ConeRadius,
			ConeAngle,
			ConeAngle,
			12,
			NotifyColor.ReinterpretAsLinear(),
			0.f,
			10.f
		);
	}

	void DrawSphere(UForceFeedbackComponent InForceFeedbackComp) const
	{
		FForceFeedbackAttenuationSettings CurrentAttenuationSettings;
		InForceFeedbackComp.GetAttenuationSettingsToApply(CurrentAttenuationSettings);

		const FTransform FinalTransform = InForceFeedbackComp.GetWorldTransform();

		float SphereRadius = CurrentAttenuationSettings.AttenuationShapeExtents.X + CurrentAttenuationSettings.FalloffDistance;
		System::DrawDebugSphere(
			FinalTransform.GetLocation(),
			SphereRadius,
			12,
			NotifyColor.ReinterpretAsLinear(),
			0.f,
			10.f
		);

		SphereRadius = CurrentAttenuationSettings.AttenuationShapeExtents.X;
		System::DrawDebugSphere(
			FinalTransform.GetLocation(),
			SphereRadius,
			12,
			NotifyColor.ReinterpretAsLinear(),
			0.f,
			10.f
		);
	}
#endif

}