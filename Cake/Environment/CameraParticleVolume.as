import Cake.Environment.Sky;

import ACameraParticleVolume AddCameraParticleVolume(AHazePlayerCharacter, ACameraParticleVolume) from "Effects.PostProcess.PostProcessing";
import ACameraParticleVolume RemoveCameraParticleVolume(AHazePlayerCharacter, ACameraParticleVolume) from "Effects.PostProcess.PostProcessing";

event void OnBecomeActiveParticleVolumeEvent();

class ACameraParticleVolume : AVolume
{
	UPROPERTY()
	int Priority = 0;

	UPROPERTY()
	UNiagaraSystem EffectToChangeTo;

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		auto ActiveVolume = AddCameraParticleVolume(Player, this);
		if(ActiveVolume == this)
			OnBecomeActiveVolume.Broadcast();
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		auto ActiveVolume = RemoveCameraParticleVolume(Player, this);
		if(ActiveVolume == this)
			OnBecomeActiveVolume.Broadcast();
    }

	UPROPERTY()
	OnBecomeActiveParticleVolumeEvent OnBecomeActiveVolume;
	
}