import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;


class UParentBlobFloatingSettingsBase : UDataAsset
{
	// How much the alpha should be multiplied with modified from both user input
	UPROPERTY(Category = "Input")
	FRuntimeFloatCurve BothInteractingAlphaMultiplier;

	// How much the alpha should be multiplied with modified from both user input
	UPROPERTY(Category = "Input")
	FRuntimeFloatCurve PerPlayerInteractingAlphaMultiplier;

	// How much the object should wobble
	UPROPERTY(Category = "Rumble")
	FVector RumbleLocationOffsetAmount; 

	// How much the object should wobble
	UPROPERTY(Category = "Rumble")
	FRotator RumbleRotationOffsetAmount; 

	// How much rumble in relation to both players interacting
	UPROPERTY(Category = "Input")
	FRuntimeFloatCurve BothInteractingRumbleMultiplier;

	void ModifyAlpha(float BothInteractingAlpha, float& InOutMayInteractionAlpha, float& InOutCodyInteractionAlpha) const
	{
		const float TotalModifier = BothInteractingAlphaMultiplier.GetFloatValue(BothInteractingAlpha, 1.f);

		InOutMayInteractionAlpha = PerPlayerInteractingAlphaMultiplier.GetFloatValue(InOutMayInteractionAlpha, InOutMayInteractionAlpha);
		InOutMayInteractionAlpha *= TotalModifier;

		InOutCodyInteractionAlpha = PerPlayerInteractingAlphaMultiplier.GetFloatValue(InOutCodyInteractionAlpha, InOutCodyInteractionAlpha);
		InOutCodyInteractionAlpha *= TotalModifier;
	}

	FTransform GetRelativeTargetTransform(AHazeActor Owner, float BothInteractingAlpha, float MayInteractionAlpha, float CodyInteractionAlpha) const
	{
		return FTransform::Identity;
	}

	FTransform GetRelativeRumbleTransform(AHazeActor Owner, float BothInteractingAlpha, float MayInteractionAlpha, float CodyInteractionAlpha) const
	{
		const FVector Scale = Owner.GetActorRelativeScale3D();
		float MayFinalAlpha = MayInteractionAlpha;
		float CodyFinalAlpha = CodyInteractionAlpha;
		ModifyAlpha(BothInteractingAlpha, MayFinalAlpha, CodyFinalAlpha);

		const float TotalAlpha = BothInteractingRumbleMultiplier.GetFloatValue((MayFinalAlpha + CodyFinalAlpha) * 0.5f, BothInteractingAlpha);
		const FVector RumbleOffset(
			RumbleLocationOffsetAmount.X * FMath::RandRange(-1.f, 1.f), 
			RumbleLocationOffsetAmount.Y * FMath::RandRange(-1.f, 1.f), 
			RumbleLocationOffsetAmount.Z * FMath::RandRange(-1.f, 1.f)
		);
		const FVector OffsetLocation = FMath::Lerp(FVector::ZeroVector, RumbleOffset, TotalAlpha) * Scale; 
		
		const FRotator RumbleRotationOffset(
			RumbleRotationOffsetAmount.Pitch * FMath::RandRange(-1.f, 1.f), 
			RumbleRotationOffsetAmount.Yaw * FMath::RandRange(-1.f, 1.f), 
			RumbleRotationOffsetAmount.Roll * FMath::RandRange(-1.f, 1.f)
		);

		const FQuat OffsetRotation = FQuat::Slerp(FQuat::Identity, RumbleRotationOffset.Quaternion(), TotalAlpha);
		return FTransform(OffsetRotation, OffsetLocation);
	}
}

class UParentBlobHorizontalRotationFloatingSettings : UParentBlobFloatingSettingsBase
{
	// How much the object should move
	UPROPERTY(Category = "Offset")
	FVector OffsetAmount;

	// How big the object is
	UPROPERTY(Category = "Offset")
	float DistanceBetweenLeftAndRight = 1000;

	FTransform GetRelativeTargetTransform(AHazeActor Owner, float BothInteractingAlpha, float MayInteractionAlpha, float CodyInteractionAlpha) const override
	{
		const FVector Scale = Owner.GetActorRelativeScale3D();
		float MayFinalAlpha = MayInteractionAlpha;
		float CodyFinalAlpha = CodyInteractionAlpha;
		ModifyAlpha(BothInteractingAlpha, MayFinalAlpha, CodyFinalAlpha);

		FVector LeftOffset = FMath::Lerp(FVector::ZeroVector,  OffsetAmount, MayFinalAlpha) * Scale; 
		LeftOffset.X -= DistanceBetweenLeftAndRight;
		
		FVector RightOffset = FMath::Lerp(FVector::ZeroVector, OffsetAmount, CodyFinalAlpha) * Scale;
		RightOffset.X += DistanceBetweenLeftAndRight;

		FVector OffsetDelta = RightOffset - LeftOffset;
		FRotator InternalRotation = OffsetDelta.Rotation();
		FVector MiddlePosition = (LeftOffset + RightOffset) * 0.5f;

		return FTransform(InternalRotation, MiddlePosition);
	}
}

class UParentBlobLiftUpFloatingSettings : UParentBlobFloatingSettingsBase
{
	UPROPERTY(Category = "Offset")
	FVector OffsetAmount;

	UPROPERTY(Category = "Offset")
	FRotator RotationAmount;

	FTransform GetRelativeTargetTransform(AHazeActor Owner, float BothInteractingAlpha, float MayInteractionAlpha, float CodyInteractionAlpha) const override
	{
		const FVector Scale = Owner.GetActorRelativeScale3D();
		float MayFinalAlpha = MayInteractionAlpha;
		float CodyFinalAlpha = CodyInteractionAlpha;
		ModifyAlpha(BothInteractingAlpha, MayFinalAlpha, CodyFinalAlpha);

		const float TotalAlpha = (MayFinalAlpha + CodyFinalAlpha) * 0.5f;
		FVector OffsetLocation = FMath::Lerp(FVector::ZeroVector, OffsetAmount, TotalAlpha) * Scale; 
		FQuat OffsetRotation = FQuat::Slerp(FQuat::Identity, RotationAmount.Quaternion(), TotalAlpha);

		return FTransform(OffsetRotation, OffsetLocation);
	}
}


class AParentBlobKineticFloatingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TransformRoot;

	UPROPERTY(DefaultComponent, Attach = TransformRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = TransformRoot)
	UParentBlobKineticInteractionComponent Interaction;

	UPROPERTY(Category = "Floating")
	bool bResetTransformRootOnComplition = true;

	UPROPERTY(Category = "Floating")
	UParentBlobFloatingSettingsBase Settings;

	UPROPERTY(Category = "Events")
	FParentBlobKineticInteractionCompletedSignature OnCompleted;

	UPROPERTY(EditConst)
	FTransform InitalTransform;
	
	bool bIsCompleted = false;
	float BothInteracting = 0;
	FQuat RumbleDirection = FQuat::Identity;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		InitalTransform = TransformRoot.RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Interaction.bHasBeenCompleted && !bIsCompleted)
		{
			if(bResetTransformRootOnComplition)
				TransformRoot.SetRelativeTransform(FTransform::Identity);

			bIsCompleted = true;
			FParentBlobKineticInteractionCompletedDelegateData CompleteData;
			CompleteData.Interaction = Interaction;
			OnCompleted.Broadcast(CompleteData);
		}

		// PrintToScreen(""+ Interaction.GetCurrentProgress());

		if (Interaction.bHasBeenCompleted)
			return;

		if(Settings != nullptr)
		{
			if(!bIsCompleted)
			{
				if(Interaction.PlayerIsInteracting(Game::GetMay()) && Interaction.PlayerIsInteracting(Game::GetCody()))
					BothInteracting = FMath::FInterpTo(BothInteracting, 1.f, DeltaSeconds, 10.f);
				else
					BothInteracting = FMath::FInterpTo(BothInteracting, 0.f, DeltaSeconds, 5.f);
			}
			else
			{
				BothInteracting = FMath::FInterpTo(BothInteracting, 1.f, DeltaSeconds, 20.f);
			}

			const float BothAlpha = (BothInteracting / 1.f);
			const float MayAlpha = Interaction.MayHoldProgress.Value / 1.f;
			const float CodyAlpha = Interaction.CodyHoldProgress.Value / 1.f;
			
			FTransform TargetRelativeTransform = Settings.GetRelativeTargetTransform(
				this,
				BothAlpha, 
				MayAlpha, 
				CodyAlpha);
			
			TargetRelativeTransform.SetLocation(InitalTransform.TransformPosition(TargetRelativeTransform.GetLocation()));
			TargetRelativeTransform.Accumulate(InitalTransform);

			if(Interaction.AnyoneIsInteracting())
			{
				FTransform RumbleRelativeTransform = Settings.GetRelativeRumbleTransform(
					this,
					BothAlpha, 
					MayAlpha, 
					CodyAlpha);

				RumbleRelativeTransform.SetLocation(InitalTransform.TransformPosition(RumbleRelativeTransform.GetLocation()));	
				TargetRelativeTransform.Accumulate(RumbleRelativeTransform);
			}
	
			// PrintToScreen("" + TargetRelativeTransform);
			TransformRoot.SetRelativeTransform(TargetRelativeTransform);
		}		
	}
}
