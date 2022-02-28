import Cake.Environment.Breakable;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifierImpactComponent;

class APortableSpeakerRoomBreakableGlass : ABreakableActor
{
	UPROPERTY(DefaultComponent)
	UMiniatureAmplifierImpactComponent AmplifierImpactComponent;

	UPROPERTY()
	float DirectionalForceMultiplier = 200.f;

	UPROPERTY()
	float ScatterForce = 10.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AmplifierImpactComponent.OnImpact.AddUFunction(this, n"Handle_AmplifierImpact");
	}	

	UFUNCTION()
	void Handle_AmplifierImpact(FAmplifierImpactInfo HitInfo)
	{
		FBreakableHitData BreakData;
		BreakData.DirectionalForce = HitInfo.DirectionFromInstigator * DirectionalForceMultiplier;
		BreakData.HitLocation = ActorLocation;
		BreakData.ScatterForce = ScatterForce;
		
		BreakableComponent.Break(BreakData);
	}
}