import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;

class UTiltVisualizerComponent : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UTiltComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UTiltComponent Comp = Cast<UTiltComponent>(Component);
        if (Comp == nullptr)
            return;

		DrawLine(Comp.WorldLocation + (Comp.ForwardVector * (Comp.TrackingLength.Y / 2)), Comp.WorldLocation + (-Comp.ForwardVector * (Comp.TrackingLength.Y / 2)), FLinearColor::Purple, 15.f);
		DrawLine(Comp.WorldLocation + (Comp.RightVector * (Comp.TrackingLength.X / 2)), Comp.WorldLocation + (-Comp.RightVector * (Comp.TrackingLength.X / 2)), FLinearColor::Purple, 15.f);
		DrawArrow(Comp.WorldLocation + (Comp.ForwardVector * (Comp.TrackingLength.Y / 2)), Comp.WorldLocation + (Comp.ForwardVector * (Comp.TrackingLength.Y / 2)) * 2.f, FLinearColor::Red, 10.f, 5.f);
		DrawArrow(Comp.WorldLocation + (-Comp.RightVector * (Comp.TrackingLength.X / 2)), Comp.WorldLocation + (-Comp.RightVector * (Comp.TrackingLength.X / 2)) * 2.f, FLinearColor::Green, 10.f, 5.f);
    }
}

struct FTiltRotationLock
{
	bool bLocked = false;
	FVector2D Dir;
}

class UTiltComponent : USceneComponent
{
	// The maximum rotation will be applied when characters are at the end of these lines
	UPROPERTY()
	FVector2D TrackingLength = FVector2D(1000.f, 1000.f);

	// The maximum rotation in degrees
	UPROPERTY()
	FVector2D MaxRotation = FVector2D(10.f, 10.f);

	// If the maximum and minumum rotation should diff.
	UPROPERTY()
	bool bUseUnevenRotationValues = false;

	// The minimum rotation in degrees
	UPROPERTY(Meta = (EditCondition = "bUseUnevenRotationValues"))
	FVector2D MinRotation = FVector2D(-10.f, -10.f);

	// The rotation speed when a player is standing on the actor
	UPROPERTY()
	float DownRotationInterpSpeed = 4.f;
	
	// The rotation speed when the actor rotates towards its original state
	UPROPERTY()
	float UpRotationInterpSpeed = 1.f;
	
	float RotationInterpSpeed = 0.f;

	// If only one specific component should trigger an impact and tilt the actor
	UPROPERTY()
	bool bSpecificImpactComponent = false;

	// Name of the component that can trigger an impact
	UPROPERTY(Meta = (EditCondition = "bSpecificImpactComponent"))
	FString ComponentToBeImpacted;

	// Use array if multiple components can trigger an impact
	UPROPERTY(Meta = (EditCondition = "bSpecificImpactComponent"))
	TArray<FString> ComponentsToBeImpacted;
	
	// Players currently on top of the actor
	TArray<AHazePlayerCharacter> PlayerArray;

	// Store Players that ground pound the actor. 
	TArray<AHazePlayerCharacter> GroundPoundingPlayerArray;

	// The component we are rotating
	USceneComponent CompToRotate;

	// If the component we are rotating should start with an rotation offset.
	UPROPERTY()
	FVector2D InitialOffset = FVector2D::ZeroVector;
	
	// If we want to preview the initial offset
	UPROPERTY()
	bool bShowInitialOffset = false;

	bool bComponentEnabled = true;

	FRotator TargetRotation = FRotator::ZeroRotator;
	FRotator InitialRotation = FRotator::ZeroRotator;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	FTiltRotationLock CodyRotationLock;
	FTiltRotationLock MayRotationLock;

	// Used to track the primitives attached to the owner
	TArray<UPrimitiveComponent> PrimArray;

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

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(Parent, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeftActor");
		BindOnDownImpactEndedByPlayer(Parent, NoImpactDelegate);

		GatherPrimitives();
		SetComponentTickEnabled(true);
	}

	void GatherPrimitives()
	{
		TArray<UActorComponent> TempArray;
		Owner.GetAllComponents(UPrimitiveComponent::StaticClass(), TempArray);
		// Gather all relevant primitives. Only saving the primitives that can trigger a tilt
		if (bSpecificImpactComponent)
		{
			for(auto Component : TempArray)
			{	
				if (Component.Name == ComponentToBeImpacted || ComponentsToBeImpacted.Contains(Component.Name))
					PrimArray.Add(Cast<UPrimitiveComponent>(Component));	
			}
		} 
		// If all primitives can trigger a tilt, save all of them
		else
		{
			for(auto Component : TempArray)
			{
				PrimArray.Add(Cast<UPrimitiveComponent>(Component));
			}
		}
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

		CheckIfPlayerLeftActor();

		FRotator PlatformRot = GetTargetTilt();
		RotationInterpSpeed = PlatformRot.IsNearlyZero() ? UpRotationInterpSpeed : DownRotationInterpSpeed;
		PlatformRot.Pitch += InitialRotation.Pitch;
		PlatformRot.Roll += InitialRotation.Roll;
		PlatformRot.Yaw += InitialRotation.Yaw;
		TargetRotation = FMath::RInterpTo(TargetRotation, PlatformRot, DeltaTime, RotationInterpSpeed);

		if (TargetRotation.Equals(PlatformRot, 0.05) && PlayerArray.Num() == 0)
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

	// Check if we allow a player to trigger "leave tilt"
	void CheckIfPlayerLeftActor()
	{
		for (int i = PlayerArray.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = PlayerArray[i];

			// if the player became airborne it's no longer on the actor
			if (Player.MovementComponent.BecameAirborne())
			{
				LeaveTiltActor(Player);
				continue;
			}
			
			if (CheckPrimitives(Player, PrimArray))
			{
				LeaveTiltActor(Player);
			}
		}
	}

	bool CheckPrimitives(AHazePlayerCharacter Player, TArray<UPrimitiveComponent> NewPrimArray)
	{
		for (UPrimitiveComponent Prim : NewPrimArray)
		{
			FVector OutVector;
			if (Prim.GetClosestPointOnCollision(Player.ActorLocation, OutVector) <= -1.f)
				continue;

			FVector Delta = OutVector - Player.ActorLocation;
			Delta = Delta.ConstrainToPlane(Player.ActorUpVector);
			
			if (Delta.Size() < Player.MovementComponent.CollisionShape.Extent.X)
				return false;
		}
		return true;
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		if (!bComponentEnabled)
			return;

		if (PlayerArray.Contains(Player))
			return;

		if (bSpecificImpactComponent)
		{
			if (Hit.Component.Name != ComponentToBeImpacted && !ComponentsToBeImpacted.Contains(Hit.Component.Name))
				return;
		}

		if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
			GroundPoundingPlayerArray.AddUnique(Player);

		PlayerArray.AddUnique(Player);
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		if (!bComponentEnabled)
			return;

		// When a player ground pound the actor, the PlayerLeftActor is triggered in the middle
		// of the ground pound. We don't want the player to be removed from the PlayerArray
		// at that point since PlayerLandedOnActor will trigger when the ground pound is done.
		if (GroundPoundingPlayerArray.Contains(Player))
		{
			GroundPoundingPlayerArray.Remove(Player);
			return;
		}		
	}

	void LeaveTiltActor(AHazePlayerCharacter Player)
	{
		PlayerArray.Remove(Player);
	}

	FRotator GetTargetTilt()
	{
		if (!ShouldTilt() && UpRotationInterpSpeed == 0.f)
			return CompToRotate.RelativeRotation;

		if (!ShouldTilt() && UpRotationInterpSpeed > 0.f)
			return FRotator::ZeroRotator;

		float CombinedXLength = 0.f;
		float CombinedYLength = 0.f;
		float LockedXLength = 0.f;
		float LockedYLength = 0.f;

		if (CodyRotationLock.bLocked)
		{
			LockedXLength += CodyRotationLock.Dir.X;
			LockedYLength += CodyRotationLock.Dir.Y;
		}

		if (MayRotationLock.bLocked)
		{
			LockedXLength += MayRotationLock.Dir.X;
			LockedYLength += MayRotationLock.Dir.Y;
		}

		for (AHazePlayerCharacter Player : PlayerArray)
		{
			float XLength = 0.f;
			float YLength = 0.f;

			if (CodyRotationLock.bLocked && Player == Game::GetCody())
				continue;

			if (MayRotationLock.bLocked && Player == Game::GetMay())
				continue;
		
			FVector Dir = Player.GetActorLocation() - CompToRotate.WorldLocation;
			XLength = FMath::Clamp(Dir.DotProduct(CompToRotate.RightVector) / (TrackingLength.X / 2), -1.f, 1.f);
			YLength = FMath::Clamp(Dir.DotProduct(CompToRotate.ForwardVector * -1) / (TrackingLength.Y / 2), -1.f, 1.f);

			CombinedXLength += XLength;
			CombinedYLength += YLength;
		}

		CombinedXLength += LockedXLength;
		CombinedYLength += LockedYLength;
		
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
		PlayerArray.Empty();
		if (bEnabled)
			SetComponentTickEnabled(true);
	}

	bool ShouldTilt()
	{
		if (PlayerArray.Num() <= 0 && !CodyRotationLock.bLocked && !MayRotationLock.bLocked)
			return false;
		else
			return true;
	}

	void LockRotationFromPlayer(AHazePlayerCharacter Player)
	{
		FVector Dir = Player.GetActorLocation() - CompToRotate.WorldLocation;
		float NewXLength = FMath::Clamp(Dir.DotProduct(CompToRotate.RightVector) / (TrackingLength.X / 2), -1.f, 1.f);
		float NewYLength = FMath::Clamp(Dir.DotProduct(CompToRotate.ForwardVector * -1) / (TrackingLength.Y / 2), -1.f, 1.f);

		if (Player == Game::GetCody())
		{
			CodyRotationLock.bLocked = true;
			CodyRotationLock.Dir = FVector2D(NewXLength, NewYLength);
		} else
		{
			MayRotationLock.bLocked = true;
			MayRotationLock.Dir = FVector2D(NewXLength, NewYLength);
		}
	}

	void ClearRotationLockFromPlayer(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetCody())
		{
			CodyRotationLock.bLocked = false;
			CodyRotationLock.Dir = FVector2D::ZeroVector;
		} else
		{
			MayRotationLock.bLocked = false;
			MayRotationLock.Dir = FVector2D::ZeroVector;
		}
	}
}
