import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongProjectile;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class UPowerfulSongProjectileBaseCapability : UHazeCapability
{
	UHazeCrumbComponent CrumbComp;
	APowerfulSongProjectile SongProjectile;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SongProjectile = Cast<APowerfulSongProjectile>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION()
	private void HandleCrumbImpactOnTarget(const FHazeDelegateCrumbData& CrumbData)
	{
		FPowerfulSongInfo Info;
		AActor HitTarget = Cast<AActor>(CrumbData.GetObject(n"HitTarget"));
		Info.Direction = CrumbData.GetVector(n"DirectionToTarget");
		Info.ImpactLocation = HitTarget.ActorLocation;
		Info.Instigator = Game::GetMay();
		USongReactionComponent ImpactComponent = USongReactionComponent::Get(HitTarget);
		ImpactComponent.PowerfulSongImpact(Info);
	}

	UFUNCTION()
	private void HandleCrumbImpact(const FHazeDelegateCrumbData& CrumbData)
	{
		AActor HitTarget = Cast<AActor>(CrumbData.GetObject(n"HitTarget"));
		FPowerfulSongInfo Info;
		Info.Direction = CrumbData.GetVector(n"DirectionToTarget");
		Info.ImpactLocation = HitTarget.ActorLocation;
		Info.Instigator = Game::GetMay();
		USongReactionComponent ImpactComponent = USongReactionComponent::Get(HitTarget);
		ImpactComponent.PowerfulSongImpact(Info);
	}
}
