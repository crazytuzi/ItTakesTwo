import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;

class UJumpingFrogTiltComponent : USceneComponent
{
		// The maximum rotation will be applied when characters are at the end of these lines
	UPROPERTY(Category = "Settings")
	FVector2D TrackingLength = FVector2D(1000.f, 1000.f);

	// The maximum rotation in degrees
	UPROPERTY(Category = "Settings")
	FVector2D MaxRotation = FVector2D(3.f, 3.f);

	// If the maximum and minumum rotation should diff.
	UPROPERTY(Category = "Settings")
	bool bUseUnevenRotationValues = false;

	// The minimum rotation in degrees
	UPROPERTY(Category = "Settings", Meta = (EditCondition = "bUseUnevenRotationValues"))
	FVector2D MinRotation = FVector2D(-3.f, -3.f);

	// The rotation speed when a player is standing on the actor
	UPROPERTY(Category = "Settings")
	float DownRotationInterpSpeed = 4.f;
	
	// The rotation speed when the actor rotates towards its original state
	UPROPERTY(Category = "Settings")
	float UpRotationInterpSpeed = 1.f;
	
	float RotationInterpSpeed = 0.f;

	// If only one specific component should trigger an impact and tilt the actor
	UPROPERTY(Category = "Settings")
	bool bSpecificImpactComponent = false;

	// Name of the component that can trigger an impact
	UPROPERTY(Meta = (EditCondition = "bSpecificImpactComponent"))
	FString ComponentToBeImpacted;
	
/* 	// Players currently on top of the actor
	TArray<AHazePlayerCharacter> PlayerArray; */

/* 	// Store Players that ground pound the actor. 
	TArray<AHazePlayerCharacter> GroundPoundingPlayerArray; */

	// Store Frogs currently on top of the actor.
	UPROPERTY()
	TArray<AJumpingFrog> JumpingFrogArray;

	// The component we are rotating
	USceneComponent CompToRotate;

	// If the component we are rotating should start with an rotation offset.
	UPROPERTY(Category = "Settings")
	FVector2D InitialOffset = FVector2D::ZeroVector;
	
	// If we want to preview the initial offset
	UPROPERTY(Category = "Settings")
	bool bShowInitialOffset = false;

	bool bComponentEnabled = true;

	FRotator TargetRotation = FRotator::ZeroRotator;
	FRotator InitialRotation = FRotator::ZeroRotator;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		// Need to cast Owner to AHazeActor to bind the Impact Delegates
		AHazeActor Parent = Cast<AHazeActor>(Owner);

		if (CompToRotate == nullptr)
		{
			CompToRotate = GetAttachParent();
			//InitialRotation = CompToRotate.RelativeRotation;
			InitialRotation = FRotator(CompToRotate.RelativeRotation.Pitch - InitialOffset.Y, CompToRotate.RelativeRotation.Yaw, CompToRotate.RelativeRotation.Roll - InitialOffset.X);
			TargetRotation = FRotator(InitialOffset.Y, CompToRotate.RelativeRotation.Yaw, InitialOffset.X);
			CompToRotate.SetRelativeRotation(FRotator(InitialOffset.Y, CompToRotate.RelativeRotation.Yaw, InitialOffset.X));
		}

		FActorImpactedDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"ActorDownImpacted");
		BindOnDownImpacted(Parent, ImpactDelegate);

		FActorNoLongerImpactingDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"ActorDownImpactEnded");
		BindOnDownImpactEnded(Parent, NoImpactDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (CompToRotate == nullptr)
		{
			CompToRotate = GetAttachParent();
			CompToRotate.SetRelativeRotation(TargetRotation);
		}

		if (bShowInitialOffset)
		{
			CompToRotate.SetRelativeRotation(FRotator(InitialOffset.Y, CompToRotate.RelativeRotation.Yaw, InitialOffset.X));
		} else  
		{
			CompToRotate.SetRelativeRotation(FRotator::ZeroRotator);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bComponentEnabled)
		{
			SetComponentTickEnabled(false);
			return;
		}

		FRotator PlatformRot = GetTargetTilt();

		RotationInterpSpeed = PlatformRot.IsNearlyZero() ? UpRotationInterpSpeed : DownRotationInterpSpeed;
		PlatformRot.Pitch += InitialRotation.Pitch;
		PlatformRot.Roll += InitialRotation.Roll;
		PlatformRot.Yaw += InitialRotation.Yaw;
		TargetRotation = FMath::RInterpTo(TargetRotation, PlatformRot, DeltaTime, RotationInterpSpeed);

		//if (TargetRotation.Equals(PlatformRot, 0.05) && (PlayerArray.Num() == 0 && JumpingFrogArray.Num() == 0))
		if (TargetRotation.Equals(PlatformRot, 0.05) && JumpingFrogArray.Num() == 0)
		{
			TargetRotation = PlatformRot;
			CompToRotate.SetRelativeRotation(TargetRotation);

			SetComponentTickEnabled(false);
		}
		else
		{
			CompToRotate.SetRelativeRotation(TargetRotation);
		}
	}

	UFUNCTION()
	void ActorDownImpacted(AHazeActor Actor, const FHitResult& Hit)
	{		
		if (!bComponentEnabled)
			return;

		if (bSpecificImpactComponent)
		{
			if (Hit.Component.Name != ComponentToBeImpacted)
				return;
		}

		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr)
		{
			JumpingFrogArray.AddUnique(Frog);
		}
/* 		else
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			
			if(Player != nullptr)
			{
				if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
					GroundPoundingPlayerArray.AddUnique(Player);

				PlayerArray.AddUnique(Player);
			}
		} */

		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void ActorDownImpactEnded(AHazeActor Actor)
	{
		if (!bComponentEnabled)
			return;
		
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr)
		{
			JumpingFrogArray.Remove(Frog);
		}
/* 		else
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

			if(Player != nullptr)
			{
				// When a player ground pound the actor, the PlayerLeftActor is triggered in the middle
				// of the ground pound. We don't want the player to be removed from the PlayerArray
				// at that point since PlayerLandedOnActor will trigger when the ground pound is done.
				if (GroundPoundingPlayerArray.Contains(Player))
				{
					GroundPoundingPlayerArray.Remove(Player);
					return;
				}
				
				PlayerArray.Remove(Player);
			}
		} */
	}

	FRotator GetTargetTilt()
	{
/* 		if (PlayerArray.Num() <= 0 && JumpingFrogArray.Num() <= 0 && UpRotationInterpSpeed == 0.f)
			return CompToRotate.RelativeRotation;

		if (PlayerArray.Num() <= 0 && JumpingFrogArray.Num() <= 0 && UpRotationInterpSpeed > 0.f)
			return FRotator::ZeroRotator;
 */

		if(JumpingFrogArray.Num() <= 0 && UpRotationInterpSpeed == 0.f)
			return CompToRotate.RelativeRotation;
		
		if(JumpingFrogArray.Num() <= 0 && UpRotationInterpSpeed > 0.f)
			return FRotator::ZeroRotator;

		float CombinedXLength = 0.f;
		float CombinedYLength = 0.f;

/* 		for (AHazePlayerCharacter Player : PlayerArray)
		{
			float XLength = 0.f;
			float YLength = 0.f;

			FVector Dir = Player.GetActorLocation() - CompToRotate.WorldLocation;
			XLength = FMath::Clamp(Dir.DotProduct(CompToRotate.RightVector) / (TrackingLength.X / 2), -1.f, 1.f);
			YLength = FMath::Clamp(Dir.DotProduct(CompToRotate.ForwardVector * -1) / (TrackingLength.Y / 2), -1.f, 1.f);

			CombinedXLength += XLength;
			CombinedYLength += YLength;
		} */

		for (AJumpingFrog Frog : JumpingFrogArray)
		{
			float XLength = 0.f;
			float YLength = 0.f;

			FVector Dir = Frog.GetActorLocation() - CompToRotate.WorldLocation;
			XLength = FMath::Clamp(Dir.DotProduct(CompToRotate.RightVector) / (TrackingLength.X / 2), -1.f, 1.f);
			YLength = FMath::Clamp(Dir.DotProduct(CompToRotate.ForwardVector * -1) / (TrackingLength.Y / 2), -1.f, 1.f);

			CombinedXLength += XLength;
			CombinedYLength += YLength;
		}
		
		float NewRoll;
		float NewPitch;
		
		if (CombinedXLength < 0.f)
		{
			NewRoll = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 0.f), FVector2D(bUseUnevenRotationValues ? MinRotation.X : -MaxRotation.X, 0.f), CombinedXLength);
		} else if (CombinedXLength > 0.f)
		{
			NewRoll = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.f, MaxRotation.X), CombinedXLength);
		} else 
		{
			NewRoll = 0.f;
		}

		if (CombinedYLength < 0.f)
		{
			NewPitch = FMath::GetMappedRangeValueClamped(FVector2D(-1.f, 0.f), FVector2D(bUseUnevenRotationValues ? MinRotation.Y : -MaxRotation.Y, 0.f), CombinedYLength);
		} else if (CombinedYLength > 0.f)
		{
			NewPitch = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.f, MaxRotation.Y), CombinedYLength);
		} else 
		{
			NewPitch = 0.f;
		}
		
		CombinedXLength = 0.f;
		CombinedYLength = 0.f;
		return FRotator(NewPitch, 0.f, NewRoll);
	}

	void SetTiltComponentEnabled(bool bEnabled)
	{
		bComponentEnabled = bEnabled;
		//PlayerArray.Empty();
		JumpingFrogArray.Empty();
		if (bEnabled)
			SetComponentTickEnabled(true);
	}
}