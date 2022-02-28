import Cake.LevelSpecific.Music.LevelMechanics.PianoKeyboard.PianoKeyboardDataAsset;

enum EPianoKeyPressedType
{
	Released,
	Pressed,
	PressedJump,
}

class UPianoKeyComponent : UStaticMeshComponent
{
	UPROPERTY(BlueprintReadOnly)
	UPianoKeyboardDataAsset Settings;
	
	UPROPERTY(BlueprintReadOnly)
	int ToneIndex = 0;
	
	UPROPERTY(BlueprintReadOnly)
	FVector ToneOffset = FVector::ZeroVector;
	
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default CollisionProfileName = n"NoCollision";

	FHazeAcceleratedFloat PressedPitch;

	float PressHeight = 120.f;
	float PressWidth = 50.f;
	float PressLengthStart = 0.f;
	float PressLengthEnd = 570.f;

	EPianoKeyPressedType PressedType = EPianoKeyPressedType::Released;
	TArray<AHazePlayerCharacter> PressingPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector BoundsMin;
		FVector BoundsMax;
		GetLocalBounds(BoundsMin, BoundsMax);
		PressHeight = BoundsMax.Z + 14.f;
		PressLengthStart = BoundsMin.X;
		PressLengthEnd = BoundsMax.X;
		PressWidth = FMath::Max(FMath::Abs(BoundsMin.Y), FMath::Abs(BoundsMax.Y)) + 4.f;
	}

	void OnHit(AHazePlayerCharacter Player, EPianoKeyPressedType PressType)
	{
		PressingPlayers.AddUnique(Player);
		OnPress(PressType);
	}

	// Press/release networking is currently handled by owners impactcomponent
	void OnPress(EPianoKeyPressedType PressType)
	{
		if (PressedType != EPianoKeyPressedType::Released)
			return;

		PressedType = PressType;
		FVector ToneLoc = WorldTransform.TransformPosition(ToneOffset);
		UHazeAkComponent::HazePostEventFireForget(GetTone(PressedType), GetWorldTransform());
		UHazeAkComponent::HazePostEventFireForget(GetPressSound(PressedType), GetWorldTransform());
		UHazeAkComponent::HazePostEventFireForget(Settings.KeyPressSound, GetWorldTransform());
		
		SetComponentTickEnabled(true);
	}

	UAkAudioEvent GetTone(EPianoKeyPressedType Type)
	{
		if (!ensure((Settings != nullptr) && (Settings.Notes.IsValidIndex(ToneIndex))))
			return nullptr;

		if ((Type == EPianoKeyPressedType::PressedJump) && (Settings.JumpNotes.IsValidIndex(ToneIndex)))
			return Settings.JumpNotes[ToneIndex];	

		return Settings.Notes[ToneIndex];
	}

	UAkAudioEvent GetPressSound(EPianoKeyPressedType Type)
	{
		if ((Type == EPianoKeyPressedType::PressedJump) && (Settings.KeyPressJumpSound != nullptr))
			return Settings.KeyPressJumpSound;	

		return Settings.KeyPressSound;
	}

	// Press/release networking is currently handled by owners impactcomponent
	void OnRelease()
	{
		if (PressedType == EPianoKeyPressedType::Released)
			return;

		PressedType = EPianoKeyPressedType::Released;
		SetComponentTickEnabled(true);

		UHazeAkComponent::HazePostEventFireForget(Settings.KeyReleaseSound, GetWorldTransform());
		UHazeAkComponent::HazePostEventFireForget(Settings.HammerReleaseSound, GetWorldTransform());	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bPressed = (PressedType != EPianoKeyPressedType::Released);
		if (bPressed)
		{
			// Check if pressing players have moved away (we need some buffer so can't rely on impact events for this)
			for (int i = PressingPlayers.Num() - 1; i >= 0; i--)
			{
				if (!IsPressingKey(PressingPlayers[i], 0.f, 0.f))
					PressingPlayers.RemoveAt(i);
			}
			if (PressingPlayers.Num() == 0)
			{
				OnRelease();
			}
		}

		// Rotate key appropriately
		if (!bPressed && FMath::IsNearlyZero(PressedPitch.Value, 0.01f))
		{
			PressedPitch.SnapTo(0.f);
			SetComponentTickEnabled(false);
		}
		else
		{
			float TargetPitch = (bPressed ? Settings.PressedAngle : 0.f);
			PressedPitch.AccelerateTo(TargetPitch, 0.2f, DeltaTime);
		}
		SetRelativeRotation(FRotator(PressedPitch.Value, 0.f, 0.f));
	}

	bool IsPressingKey(AHazePlayerCharacter Player, float VerticalThreshold, float HorizontalThreshold)
	{
		// Check in local space of key in unpressed pose
		FTransform UnpressedTransform = WorldTransform;
		UnpressedTransform.ConcatenateRotation(FQuat(FRotator(-PressedPitch.Value, 0.f, 0.f)));

		// Use player capsule bottom, top or closest center location depending on player vs key alignment
		FVector PlayerLoc = Player.CapsuleComponent.WorldLocation;
		float PlayerWidth;
		FVector KeyUpVector = UnpressedTransform.Rotation.UpVector;
		float UpDot = KeyUpVector.DotProduct(Player.ActorUpVector);
		if (UpDot > 0.7f)
		{
			PlayerLoc -= Player.ActorUpVector * Player.CapsuleComponent.ScaledCapsuleHalfHeight;
			PlayerWidth = Player.CapsuleComponent.ScaledCapsuleRadius;
		}
		else if (UpDot < -0.7f)
		{
			PlayerLoc += Player.ActorUpVector * Player.CapsuleComponent.ScaledCapsuleHalfHeight;
			PlayerWidth = Player.CapsuleComponent.ScaledCapsuleRadius;
		}
		else
		{
			PlayerLoc -= UpVector * Player.CapsuleComponent.ScaledCapsuleRadius;
			PlayerWidth = Player.CapsuleComponent.ScaledCapsuleHalfHeight * 0.6f;
		}

		FVector PlayerLocalLoc = UnpressedTransform.InverseTransformPosition(PlayerLoc);
		if (PlayerLocalLoc.Z > PressHeight - VerticalThreshold)
		{
			// Above key, no longer pressing
			return false;
		}
		else 
		{
			// Outside horizontal bounds?
			PlayerWidth -= HorizontalThreshold;
			if (FMath::Abs(PlayerLocalLoc.Y) > PressWidth + (PlayerWidth / FMath::Max(0.01f, WorldTransform.Scale3D.Y))) 
				return false;
			if (PlayerLocalLoc.X < PressLengthStart - (PlayerWidth / FMath::Max(0.01f, WorldTransform.Scale3D.X)))
				return false;
			if (PlayerLocalLoc.X > PressLengthEnd + (PlayerWidth / FMath::Max(0.01f, WorldTransform.Scale3D.X)))
				return false;
		} 	

		// On top of key!
		return true;
	}

	FVector GetKeySize()
	{
		FVector KeyMin, KeyMax;
		GetLocalBounds(KeyMin, KeyMax);
		return (KeyMax - KeyMin);
	}
}
