import Cake.LevelSpecific.Music.LevelMechanics.PianoKeyboard.PianoKeyBoard;
import Vino.Movement.Components.WallSlideCallbackComponent;

// Place this component encapsulating a piano if you want piano to be affected by collisions against this as if player actually hit piano.
// Useful for pianos used for wallclimbing etc, as this will not slope like the collision of a regular piano.
class APianoCollisionCover : AHazeActor
{
#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif	

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent CollisionComp;
	default CollisionComp.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default CollisionComp.AddTag(ComponentTags::WallSlideable);
	default CollisionComp.AddTag(ComponentTags::WallRunnable);
	default CollisionComp.AddTag(ComponentTags::LedgeGrabbable);

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundDetector;

	// Impact detector bCanBeActivedLocallyOnTheRemote can be true for better responsiveness if keyboard does not affect gameplay. 
	// TODO: set to true if there are no delegates bound on keyboard for both groundpound, impact and wallslide detectors
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactDetector;
	default ImpactDetector.bCanBeActivedLocallyOnTheRemote = false; 

	// When wall sliding on this, we will get ending impacts immediately when starting wall slide, so need to keep track of this separately
	UPROPERTY(DefaultComponent)
	UPlayerWallSlidingOnCallbackComponent WallSlideDetector;

	UPROPERTY()
	APianoKeyboard KeyBoard = nullptr;

	TArray<AHazePlayerCharacter> TouchingPlayers;
	TArray<AHazePlayerCharacter> WallSliders;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (KeyBoard == nullptr)
			SnapToKeyBoardInternal(GetClosestKeyboard(5000.f));
	}

	APianoKeyboard GetClosestKeyboard(float Radius)
	{
		APianoKeyboard ClosestKeyBoard = nullptr;
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);
		TArray<AActor> IgnoreActors;
		TArray<AActor> NearbyKeyBoards;
		if (System::SphereOverlapActors(ActorLocation, Radius, ObjectTypes, APianoKeyboard::StaticClass(), IgnoreActors, NearbyKeyBoards))
		{
			float ClosestDistSqr = BIG_NUMBER;
			for (AActor Actor : NearbyKeyBoards)
			{
				APianoKeyboard NearbyKeyBoard = Cast<APianoKeyboard>(Actor);
				if (NearbyKeyBoard == nullptr)
					continue;
				float DistSqr = GetSquaredDistanceTo(NearbyKeyBoard);
				if (DistSqr < ClosestDistSqr)
				{
					ClosestDistSqr = DistSqr;	
					ClosestKeyBoard = NearbyKeyBoard;
				}
			}
		}
		return ClosestKeyBoard;
	}


	UFUNCTION(CallInEditor)
	void SnapToKeyBoard()
	{
		if (KeyBoard == nullptr)
			SnapToKeyBoardInternal(GetClosestKeyboard(20000.f));
		else
			SnapToKeyBoardInternal(KeyBoard);
		CollisionComp.MarkRenderStateDirty();
	}

	void SnapToKeyBoardInternal(APianoKeyboard NewKeyBoard)
	{
		if (NewKeyBoard == nullptr)
			return;

		KeyBoard = NewKeyBoard;
		FTransform CoverTransform = KeyBoard.GetActorTransform();
		CoverTransform.Location = KeyBoard.WhiteKeysCollision.WorldLocation;
		SetActorTransform(CoverTransform);

		FVector Extents = KeyBoard.WhiteKeysCollision.BoxExtent;
		for (UPianoKeyComponent Key : KeyBoard.Keys)
		{
			if (Key.StaticMesh == KeyBoard.Settings.BlackKeyMesh)
			{
				Extents.Z = (Key.GetKeySize().Z - Key.Settings.BlackKeyOffset.Z) * Key.RelativeScale3D.Z;
				break;
			}
		}
		CollisionComp.BoxExtent = Extents;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundDetector.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");
		ImpactDetector.OnActorDownImpactedByPlayer.AddUFunction(this, n"OnPlayerHit");	
		ImpactDetector.OnDownImpactEndingPlayer.AddUFunction(this, n"OnPlayerLeave");	
		ImpactDetector.OnActorForwardImpactedByPlayer.AddUFunction(this, n"OnPlayerHit");	
		ImpactDetector.OnForwardImpactEndingPlayer.AddUFunction(this, n"OnPlayerLeave");	
		ImpactDetector.OnActorUpImpactedByPlayer.AddUFunction(this, n"OnPlayerHit");	
		ImpactDetector.OnUpImpactEndingPlayer.AddUFunction(this, n"OnPlayerLeave");	
		WallSlideDetector.OnStartedWallSlidingOn.AddUFunction(this, n"OnWallSlideStart");
		WallSlideDetector.OnStoppedWallSlidingOn.AddUFunction(this, n"OnWallSlideStop");

		SetActorTickEnabled(false);

		// Disable collision on the keyboard itself. Cover should handle all impact/groundpound events.
		KeyBoard.SetActorEnableCollision(false);
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter GroundPounder)
	{
		if (KeyBoard == nullptr)
			return;
		KeyBoard.OnGroundPounded(GroundPounder);
	}

	UFUNCTION()
	void OnPlayerHit(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		if (KeyBoard == nullptr)
			return;
		FHitResult KeyHit = Hit;
		KeyHit.Component = KeyBoard.WhiteKeysCollision;
		KeyBoard.OnPlayerHit(Player, KeyHit);

		TouchingPlayers.AddUnique(Player);
	}

	UFUNCTION()
	void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (KeyBoard == nullptr)
			return;
		
		// Leave unless we're wall sliding instead
		if (!WallSliders.Contains(Player))
			PlayerLeft(Player);
	}

	UFUNCTION()
	void OnWallSlideStart(AHazePlayerCharacter Player, UPrimitiveComponent Primitive)
	{
		WallSliders.AddUnique(Player);
		TouchingPlayers.AddUnique(Player);
	}

	UFUNCTION()
	void OnWallSlideStop(AHazePlayerCharacter Player, UPrimitiveComponent Primitive, bool bJumpedOff)
	{
		WallSliders.RemoveSwap(Player);
		PlayerLeft(Player);
	}

	void PlayerLeft(AHazePlayerCharacter Player)
	{
		KeyBoard.OnPlayerLeave(Player);
		TouchingPlayers.Remove(Player);
	}
}