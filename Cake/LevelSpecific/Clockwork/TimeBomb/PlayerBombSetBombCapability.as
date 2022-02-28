import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;

class UPlayerBombSetBombCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerBombSetBombCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UPlayerTimeBombComp PlayerComp;

	float RaceTimeRef;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerTimeBombComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.TimeBombState == ETimeBombState::Spawned)
	        return EHazeNetworkActivation::ActivateFromControl;

		if (PlayerComp.TimeBombState == ETimeBombState::Ticking)
	        return EHazeNetworkActivation::ActivateFromControl;

		if (Player.IsPlayerDead())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.TimeBombState == ETimeBombState::Default)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.BombMesh = Cast<ABombMesh>(SpawnActor(PlayerComp.BombMeshClass)); 
		PlayerComp.BombMesh.AttachToComponent(Player.Mesh, n"RideSocket");
		FVector OffsetUpDir = PlayerComp.BombMesh.ActorUpVector;
		FVector OffsetFwdDir = PlayerComp.BombMesh.ActorForwardVector;
		PlayerComp.BombMesh.ActorLocation -= OffsetUpDir * 50.f;
		PlayerComp.BombMesh.ActorLocation -= OffsetFwdDir * 15.f;

		if (PlayerComp.BombSpawnEffect != nullptr)
			Niagara::SpawnSystemAtLocation(PlayerComp.BombSpawnEffect, PlayerComp.BombMesh.ActorLocation, FRotator(0.f));

		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		RaceTimeRef = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
		{
		if (PlayerComp.BombMesh != nullptr)
			PlayerComp.BombMesh.BombDisappears();
		
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		RaceTimeRef += DeltaTime;
	}
}