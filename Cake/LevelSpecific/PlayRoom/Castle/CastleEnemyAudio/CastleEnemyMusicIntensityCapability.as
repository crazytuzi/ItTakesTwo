import Vino.AI.Audio.MusicIntensityTeam;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAudio.CastleMusicIntensity;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

class UCastleEnemyMusicIntensityCapability : UHazeCapability
{
	UMusicIntensityTeam MusicIntensityTeam;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		ACastleEnemy CastleEnemy = Cast<ACastleEnemy>(Owner);
		MusicIntensityTeam = Cast<UMusicIntensityTeam>(CastleEnemy.JoinTeam(CastleMusicIntensity::TeamName, UMusicIntensityTeam::StaticClass()));
		CastleEnemy.OnKilled.AddUFunction(this, n"OnMusicIntensityClear");
		if (CastleEnemy.MusicIntensityType == ECastleEnemyMusicIntensityType::Default)
			CastleEnemy.OnAggroed.AddUFunction(this, n"OnMusicIntensityCombat");
    }

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
    {
		MusicIntensityTeam.ReportThreatOver(Owner);
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		// Will currently not do anything but respond to events
        return EHazeNetworkActivation::DontActivate; 
    }

	UFUNCTION(NotBlueprintCallable)
	void OnMusicIntensityClear(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		MusicIntensityTeam.ReportThreatOver(Enemy);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMusicIntensityCombat(ACastleEnemy Enemy, AHazePlayerCharacter Player, FCastleEnemyAggroFlags AggroFlags)
	{
		if (Enemy.bDead || Enemy.bKilled)
			return;
		MusicIntensityTeam.ReportCombat(Enemy);
	}
}

class UCastleEnemyAlwaysCombatMusicIntensityCapability : UCastleEnemyMusicIntensityCapability
{
	bool bHasActivated = false;

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (bHasActivated)
        	return EHazeNetworkActivation::DontActivate; 
		if (Owner.IsActorDisabled())
        	return EHazeNetworkActivation::DontActivate; 
       	return EHazeNetworkActivation::ActivateLocal; 
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MusicIntensityTeam.ReportCombat(Owner);
		bHasActivated = true;		
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
    {
		bHasActivated = false;
		Super::OnRemoved();
	}
}