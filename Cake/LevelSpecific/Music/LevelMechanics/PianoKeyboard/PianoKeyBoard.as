import Cake.LevelSpecific.Music.LevelMechanics.PianoKeyboard.PianoKeyComponent;
import Cake.LevelSpecific.Music.LevelMechanics.PianoKeyboard.PianoKeyboardDataAsset;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.MovementSettings;

UCLASS(Abstract, Meta = (HideCategories = "Rendering Replication Actor Tick Input Capability Debug LOD Collision Cooking"))
class APianoKeyboard : AHazeActor
{
	// Index of the first key of the keyboard
	UPROPERTY(Category = "Keyboard")
	int StartingKeyIndex = 0; 

	// Number of keys that will be automatically created for this keyboard
	UPROPERTY(Category = "Keyboard")
	int NumKeys = 88;

	// Local offset from each key where the tone is generated, i.e. where the hammer hits the string on a piano. 
	UPROPERTY(Category = "Keyboard", meta = (MakeEditWidget = true))
	FVector ToneOffset = FVector(-500.f, 0.f, -100.f);

	UPROPERTY(Category = "Keyboard")
	UPianoKeyboardDataAsset Settings;	

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent KeyboardRoot;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundDetector;

	// Impact detector bCanBeActivedLocallyOnTheRemote can be true for better responsiveness if keyboard does not affect gameplay. 
	// TODO: set to true if there are no delegates bound on keyboard for both groundpound and impact detector
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactDetector;
	default ImpactDetector.bCanBeActivedLocallyOnTheRemote = false; 

	UPROPERTY(DefaultComponent)
	UBoxComponent WhiteKeysCollision;
	default WhiteKeysCollision.CollisionProfileName = n"BlockAll";

	UPROPERTY()
	TArray<UPrimitiveComponent> BlackKeysCollision;

	UPROPERTY()
	bool bAutoAdjustWhiteKeysCollision = true;
	 
	UPROPERTY(BlueprintHidden)
	TArray<UPianoKeyComponent> Keys;

	TArray<AHazePlayerCharacter> PressingPlayers;
	
	int NumConfigurationWhiteKeys = 0;

	UPROPERTY()
	bool bUseBlackKeyCollision = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<UActorComponent> Comps;
		GetAllComponents(UActorComponent::StaticClass(), Comps);

		if (Settings == nullptr)
			return;

		// A piano keyboard should not start with a black key
		while ((StartingKeyIndex > 0) && (GetKeyType(StartingKeyIndex) == EPianoKeyType::Black))
			StartingKeyIndex--;

		// Sanity check of number of keys
		if (NumKeys > Settings.Notes.Num())
			NumKeys = Settings.Notes.Num();
		if (StartingKeyIndex + NumKeys > Settings.Notes.Num())
		{
			StartingKeyIndex = Settings.Notes.Num() - NumKeys;
			while ((StartingKeyIndex > 0) && (GetKeyType(StartingKeyIndex) == EPianoKeyType::Black))
				StartingKeyIndex--;
		}

		// A piano keyboard should not end with a black key
		while ((StartingKeyIndex + NumKeys < Settings.Notes.Num()) && (GetKeyType(StartingKeyIndex + NumKeys - 1) == EPianoKeyType::Black))
			NumKeys++;

		// All previous non-default comps will be thrashed, so don't reuse them
		for (UPianoKeyComponent OldComp : Keys)
		{
			if (OldComp != nullptr)
				OldComp.DestroyComponent(this);
		}
		Keys.Empty(NumKeys);
		for (UPrimitiveComponent OldKeyCollision : BlackKeysCollision)
		{
			if (OldKeyCollision != nullptr)
				OldKeyCollision.DestroyComponent(this);
		}
		BlackKeysCollision.Empty(BlackKeysCollision.Num());

		// Set up the keys
		FVector KeyLocalLoc = -Settings.WhiteKeyOffset;
		for (int i = StartingKeyIndex; i < StartingKeyIndex + NumKeys; i++)
		{
			UPianoKeyComponent KeyComp = Cast<UPianoKeyComponent>(CreateComponent(UPianoKeyComponent::StaticClass()));
			KeyComp.ToneOffset = ToneOffset;
			KeyComp.ToneIndex = i;
			KeyComp.Settings = Settings;
			Keys.Add(KeyComp);

			EPianoKeyType KeyType = GetKeyType(i);
			if (KeyType == EPianoKeyType::Black)
			{
				// Set black key mesh, don't update local loc (black keys are assumed to be placed in between white keys)
				KeyComp.StaticMesh = Settings.BlackKeyMesh;
				KeyComp.RelativeLocation = KeyLocalLoc + Settings.BlackKeyOffset;
				KeyComp.RelativeScale3D = Settings.BlackKeyScale;

				if(bUseBlackKeyCollision == true)
				{
					// Create static collision for black key in pressed down position
					UBoxComponent KeyCollision = Cast<UBoxComponent>(CreateComponent(UBoxComponent::StaticClass()));
					KeyCollision.CollisionProfileName = n"BlockAll";
					FVector KeySize = KeyComp.GetKeySize();
					KeyCollision.RelativeLocation = KeyComp.RelativeLocation + FVector(KeySize.X * 0.5f, 0.f, KeySize.Z + Settings.BlackKeyOffset.Z);
					KeyCollision.RelativeRotation = FRotator(Settings.PressedAngle, 0.f, 0.f);
					KeyCollision.BoxExtent = KeyComp.GetKeySize() * 0.5f;
					BlackKeysCollision.Add(KeyCollision);
				}
			}
			else
			{
				// White key, check neighbours to decide mesh
				bool bBlackBefore = (i > StartingKeyIndex) && (GetKeyType(i - 1) == EPianoKeyType::Black);
				bool bBlackAfter = (i < StartingKeyIndex + NumKeys - 1) && (GetKeyType(i + 1) == EPianoKeyType::Black);
				if (bBlackBefore && bBlackAfter)
					KeyComp.StaticMesh = Settings.WhiteKeyMesh_Middle;
				else if (bBlackBefore)
					KeyComp.StaticMesh = Settings.WhiteKeyMesh_Right;
				else if (bBlackAfter)
					KeyComp.StaticMesh = Settings.WhiteKeyMesh_Left;
				else
					KeyComp.StaticMesh = Settings.WhiteKeyMesh_Blank;

				// Update and set location 
				KeyLocalLoc += Settings.WhiteKeyOffset;
				KeyComp.RelativeLocation = KeyLocalLoc;
			}
		}

		WhiteKeysCollision.AddTag(n"KeyBoardCollision");
		if (bAutoAdjustWhiteKeysCollision && (Keys.Num() > 0))
		{
			// Set up collision component for white keys
			// We always start with a white key and assume all white keys have the same extents.
			FVector KeySize = Keys[0].GetKeySize();

			// Collision should cover depressed keys
			WhiteKeysCollision.RelativeRotation = FRotator(Settings.PressedAngle, 0.f, 0.f);

			// Center on and cover entire keyboard width
			WhiteKeysCollision.RelativeLocation = KeyLocalLoc * 0.5f;
			WhiteKeysCollision.BoxExtent.Y = (FMath::Abs(KeyLocalLoc.Y) + KeySize.Y) * 0.5f;
			
			// Offset by size of key
			FVector CenterOffset = FVector(KeySize.X * 0.5f, 0.f, KeySize.Z * 0.25f);
			WhiteKeysCollision.RelativeLocation += CenterOffset;  

			// Match key Length and height
			WhiteKeysCollision.BoxExtent.X = KeySize.X * 0.5f;
			WhiteKeysCollision.BoxExtent.Z = KeySize.Z * 0.5f;
		}
	}

	EPianoKeyType GetKeyType(int KeyIndex)
	{
		if (Settings == nullptr)
			return EPianoKeyType::White;
		int ConfigIndex = KeyIndex % Settings.Configuration.Num();
		return Settings.Configuration[ConfigIndex];
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundDetector.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");
		ImpactDetector.OnActorDownImpactedByPlayer.AddUFunction(this, n"OnPlayerHit");	
		ImpactDetector.OnDownImpactEndingPlayer.AddUFunction(this, n"OnPlayerLeave");	

		if (Settings != nullptr)
		{
			for (EPianoKeyType KeyType : Settings.Configuration)
			{
				if (KeyType == EPianoKeyType::White)
					NumConfigurationWhiteKeys++;
			}
		}

		SetActorTickEnabled(false);	
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter GroundPounder)
	{
		if (Settings.GroundPounded == nullptr)
			return;	
		UHazeAkComponent::HazePostEventFireForget(Settings.GroundPounded, GroundPounder.GetActorTransform());
	}

	UFUNCTION()
	void OnPlayerHit(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		UMovementSettings::SetStepUpAmount(Player, 60.f, this);
		PressingPlayers.AddUnique(Player);
		UpdatePressedKeys(Player);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearSettingsByInstigator(this);
		PressingPlayers.Remove(Player);
		if (PressingPlayers.Num() == 0)
			SetActorTickEnabled(false);

		// Don't report this to keys. Key will keep track of player and count them as pressing until they're some ways away.	
	}

	int GetKeyIndex(UPianoKeyComponent Key)
	{
		return (Key.ToneIndex - StartingKeyIndex);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : PressingPlayers)
		{
			UpdatePressedKeys(Player);
		}
	}

	void UpdatePressedKeys(AHazePlayerCharacter Player)
	{
		// Find key below player collision center
		UPianoKeyComponent CenterKey = GetKeyAt2D(Player.CapsuleComponent.WorldLocation);
		if (CenterKey == nullptr)
			return;
		
		EPianoKeyPressedType PressType = EPianoKeyPressedType::Pressed;
		if (Player.ActualVelocity.Z < -1000.f)
			PressType = EPianoKeyPressedType::PressedJump;

		// Check if we're pressing center key or it's neighbours
		int iCenterKey = GetKeyIndex(CenterKey);
		for (int i = iCenterKey - 2; i < iCenterKey + 3; i++)
		{
			if (!Keys.IsValidIndex(i))
				continue;

			UPianoKeyComponent Key = Keys[i];
			if (Key.PressingPlayers.Contains(Player))
				continue;
			if (Key.IsPressingKey(Player, 5.f, 20.f))
				Key.OnHit(Player, PressType);
		}
	}

	UPianoKeyComponent GetKeyAt2D(const FVector& WorldLoc)
	{
		if (Settings == nullptr)
			return nullptr;

		FVector LocalLoc = ActorTransform.InverseTransformPosition(WorldLoc);
		int iWhiteKey = StartingKeyIndex + FMath::TruncToInt((LocalLoc.Y + (Settings.WhiteKeyOffset.Y * 0.5f)) / Settings.WhiteKeyOffset.Y);
		int iWhiteKeyCount = iWhiteKey % NumConfigurationWhiteKeys; 
		int i = 0;
		for (; i < Settings.Configuration.Num(); i++)
		{
			if (Settings.Configuration[i] == EPianoKeyType::White)
			{
				if (iWhiteKeyCount == 0)
					break; // Found white key within sequence
				iWhiteKeyCount--;
			}			
		}
		int iKey = i + (iWhiteKey / NumConfigurationWhiteKeys) * Settings.Configuration.Num();
		if (!Keys.IsValidIndex(iKey) || !System::IsValid(Keys[iKey]))
			return nullptr;

		FVector KeyLocalLoc = Keys[iKey].WorldTransform.InverseTransformPosition(WorldLoc); 
		UPianoKeyComponent BlackKey = nullptr;
		if (KeyLocalLoc.Y > 0.f) 
		{
			if ((iKey > StartingKeyIndex) && (GetKeyType(iKey-1) == EPianoKeyType::Black))
				BlackKey = Keys[iKey-1];
		}
		else 
		{
			if ((iKey < StartingKeyIndex + NumKeys - 1) && (GetKeyType(iKey+1) == EPianoKeyType::Black))
				BlackKey = Keys[iKey+1];
		}
		if (BlackKey != nullptr)
		{
			// Check if we hit the black key	
			FVector BoundsMin;
			FVector BoundsMax;
			BlackKey.GetLocalBounds(BoundsMin, BoundsMax);
			FVector BlackKeyLocalLoc = BlackKey.WorldTransform.InverseTransformPosition(WorldLoc);
			const float Threshold = 30.f;
			if ((BlackKeyLocalLoc.X < BoundsMax.X + Threshold) && (BlackKeyLocalLoc.X > BoundsMin.X - Threshold) &&
				(BlackKeyLocalLoc.Y < BoundsMax.Y + Threshold) && (BlackKeyLocalLoc.Y > BoundsMin.Y - Threshold))
			{
				// We hit the black key
				return BlackKey;
			}
		}					
		// We hit the white key
		return Keys[iKey];
	}	
}
