import Cake.Weapons.Sap.SapWeaponContainer;
import Cake.Weapons.Sap.SapStream;
import Cake.Weapons.Sap.SapManager;
import Cake.Weapons.Sap.SapWeaponAimStatics;
import Vino.Trajectory.TrajectoryStatics;
import Peanuts.Audio.AudioStatics;

class ASapWeapon : AHazeActor
{
	// Mesh stuff
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.AddTag(ComponentTags::HideOnCameraOverlap);

	UPROPERTY(DefaultComponent)
	USceneComponent HandIkAttach;

	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.SetCollisionProfileName(n"WeaponDefault");

	UPROPERTY(Category = "Capability")
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY(Category = "Container")
	TSubclassOf<ASapWeaponContainer> ContainerClass;
	ASapWeaponContainer Container;

	UPROPERTY(Category = "Sap", EditDefaultsOnly)
	TSubclassOf<USapStream> StreamClass;
	USapStream Stream;

	UPROPERTY(Category = "Sap", EditDefaultsOnly)
	TSubclassOf<USapManager> ManagerClass;
	USapManager SapManager;

	// Variables used for visuals, not for gameplay
	UPROPERTY(Category = "Animation")
	float CurrentFireRate = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilitySheetRequest(PlayerSheet, EHazeCapabilitySheetPriority::Normal, EHazeSelectPlayer::Cody);
		Container = Cast<ASapWeaponContainer>(SpawnActor(ContainerClass, Level = this.Level));
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		auto PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		if(PlayerOwner != nullptr)
			PlayerOwner.OnHiddenInGameStatusChanged.UnbindObject(this);

		Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet, EHazeCapabilitySheetPriority::Normal, EHazeSelectPlayer::Cody);

		Container.DestroyActor();
		if (Stream != nullptr)
			Stream.DestroyObject();
		if (SapManager != nullptr)
			SapManager.DestroyObject();

		BP_StopUnderWaterShot();
	}

	// Initializes the sap gun with all mumbo jumbo
	// Can not be called from BeginPlay, since stuff is spawned
	// Sometimes called from BP, if the sap gun is used outside of the SapWeapon system (like cutscenes)
	UFUNCTION()
	void Init(UObject WeaponOwner)
	{
		SetControlSide(WeaponOwner);

		SapManager = Cast<USapManager>(NewObject(this, ManagerClass));
		SapManager.SetWorldContext(this);
		SapManager.MakeNetworked(this);
		SapManager.Init();

		Stream = Cast<USapStream>(NewObject(this, StreamClass));
		Stream.SetWorldContext(this);
		Stream.Init(SapManager);
			
		auto PlayerOwner = Cast<AHazePlayerCharacter>(WeaponOwner);
		if(PlayerOwner != nullptr)
			PlayerOwner.OnHiddenInGameStatusChanged.AddUFunction(this, n"OnPlayerHiddenInGameStatusChanged");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerHiddenInGameStatusChanged(AHazeActor ThisPlayer, bool bPlayerHidden)
	{
		/*
		SetActorHiddenInGame(bPlayerHidden);
		if(Container != nullptr)
			Container.SetActorHiddenInGame(bPlayerHidden);
			*/
	}

	UFUNCTION(Category = "Weapon|Sap")
	void FireProjectile(FVector Velocity, FSapAttachTarget Target)
	{
		Stream.FireParticle(MuzzleLocation, Velocity, Target);
		BP_ProjectileFired();
	}

	FVector GetMuzzleLocation() property
	{
		return Mesh.GetSocketLocation(n"Muzzle");
	}

	UFUNCTION(BlueprintPure, Category = "Weapon|Sap")
	FTransform GetMuzzleTransform() property
	{
		return Mesh.GetSocketTransform(n"Muzzle");
	}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_StartFiring()
	{
		
	}
	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_StopFiring()
	{
		
	}
	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_ProjectileFired()
	{

	}
	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_StartUnderWaterShot()
	{

	}
	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void BP_StopUnderWaterShot()
	{

	}
}
