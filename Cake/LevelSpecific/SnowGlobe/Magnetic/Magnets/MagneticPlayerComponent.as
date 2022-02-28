import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerMagnetActor;

event void FOnPlayersReadyToLaunch();

// this is the magnet on the player
class UMagneticPlayerComponent : UMagneticComponent
{
	FVector DesiredCollisionLocation = FVector::ZeroVector;
	bool bIsBeingAttractedByOtherPlayer = false;

	FOnPlayersReadyToLaunch OnPlayersReadyToLaunch; 
	private FLinearColor PlayerOldColor;
	private bool bHasBlockedNewSeek = false;

	// This will make the player magnet less prioritesed
	default DistanceMaxScore  = 10.f; // Default is 100;
	default CameraMaxScore = 10.f; // Default is 100;

	UPROPERTY(Category = "Attribute")
	TSubclassOf<APlayerMagnetActor> PlayerMagnetActorClass;

	UPROPERTY(Category = "Attribute")
	USkeletalMesh MagnetMesh;

	APlayerMagnetActor PlayerMagnet;
	int MagnetSpawnCounter = 0;

	AHazePlayerCharacter Player;

	// Can be optionally used when evaluating other magnet components' setup.
	// Needs to be written to before magnets are updated
	FVector PlayerInputBias;

	UMagneticComponent PrioritizedMagnet = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerOldColor = Player.PlayerColor;
		
		if(Polarity == EMagnetPolarity::Plus_Red)
		{
			Player.SetCustomPlayerColor(FLinearColor::Red);
		}
		else if(Polarity == EMagnetPolarity::Minus_Blue)
		{
			Player.SetCustomPlayerColor(FLinearColor::Blue);
		}

		AttachToComponent(Player.Mesh, n"Head");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Player.SetCustomPlayerColor(PlayerOldColor);

		if(PlayerMagnet != nullptr && !PlayerMagnet.IsActorBeingDestroyed())
			PlayerMagnet.DestroyActor();
	}

	void QueryMagnets()
	{
		Player.UpdateActivationPointAndWidgets(UMagneticComponent::StaticClass());
	}

	UHazeActivationPoint GetTargetedMagnet()const property
	{
		return Player.GetTargetPoint(UMagneticComponent::StaticClass());
	}

	UHazeActivationPoint GetActivatedMagnet()const property
	{
		return Player.GetActivePoint();
	}

	// Activating a magnet lockon will deactivate the current lockon
	void ActivateMagnetLockon(UMagneticComponent Magnet, UObject Instigator)
	{
		Player.ActivatePoint(Magnet, Instigator);
		PlayerMagnet.OnMagnetActivated.Broadcast(Magnet, HasEqualPolarity(Magnet));
	}

	// Removes the current locked on magnet if the instigator is the one that is currently locked on
	void DeactivateMagnetLockon(UObject Instigator)
	{
		UMagneticComponent ActiveMagnet = Cast<UMagneticComponent>(GetActivatedMagnet());
		if(ActiveMagnet != nullptr)
			PlayerMagnet.OnMagnetDeactivated.Broadcast(ActiveMagnet, HasEqualPolarity(ActiveMagnet));

		Player.DeactivateCurrentPoint(Instigator);
	}

	// Returns if the instigator is the object that is currently locked on the magnet
	bool MagnetLockonIsActivatedBy(UObject Instigator)const
	{
		return Player.CurrentActivationInstigatorIs(Instigator);
	}

	void UpdateActiveMagnet(UMagneticComponent ActiveMagnet) override
	{
		// Update distance to magnet
		PlayerMagnet.NormalDistanceToTargetMagnet = Math::Saturate(Player.ActorLocation.Distance(ActiveMagnet.WorldLocation) / ActiveMagnet.GetDistance(EHazeActivationPointDistanceType::Selectable));
	}

	float GetTargetDistanceAlpha() property
	{
		FHazeQueriedActivationPoint TargetQuery;
		if(Player.GetTargetPoint(UMagneticComponent::StaticClass(), TargetQuery))
		{
			if(TargetQuery.Point.IsA(UMagneticComponent::StaticClass()))
				return TargetQuery.DistanceAlpha;
		}

		return 1.f;
	}

	void SpawnMagnetActor()
	{
		if(!PlayerMagnetActorClass.IsValid())
			return;

		PlayerMagnet = Cast<APlayerMagnetActor>(SpawnActor(PlayerMagnetActorClass, bDeferredSpawn = true));
		PlayerMagnet.MakeNetworked(this, MagnetSpawnCounter++);
		PlayerMagnet.SetControlSide(Player);

		PlayerMagnet.Initialize(Player, MagnetMesh);

		FinishSpawningActor(PlayerMagnet);
	}

	void SetMagnetMeshIsHidden(bool bIsHidden)
	{
		PlayerMagnet.SetActorHiddenInGame(bIsHidden);
	}

	UFUNCTION()
	APlayerMagnetActor GetPlayerMagnet() const
	{
		return PlayerMagnet;
	}
}