import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;
import Cake.LevelSpecific.Clockwork.TimeBomb.BombMesh;

class UTagSetBombCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TagSetBombCapability");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"Tag";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USpiderTagPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USpiderTagPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.bWeAreIt)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PlayerComp.bWeAreIt)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.BombMesh = Cast<ABombMesh>(SpawnActor(PlayerComp.BombMeshClass)); 
		PlayerComp.BombMesh.AttachToComponent(Player.Mesh, n"RideSocket");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//Spawn puff of smoke for bomb
		PlayerComp.BombMesh.BombDisappears();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (PlayerComp.BombMesh != nullptr)
			PlayerComp.BombMesh.BombDisappears();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// RaceTimeRef += DeltaTime;
	}

	UFUNCTION()
	void DestroyBomb()
	{

	}

}