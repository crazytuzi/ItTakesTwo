import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BackstageAudio.PowerfulSongMicSpeakerAudioReactionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifierImpactComponent;
class USwayMicrophoneComponent : USceneComponent
{
	USceneComponent CompToRotate;
	USongReactionComponent SongReactComp;
	UMiniatureAmplifierImpactComponent AmpImpComp;
	UPowerfulSongMicSpeakerAudioReactionComponent SpeakerReactComp;
	float InitialPitch = 0.f;
	float CurrentPitchMultiplier;

	UPROPERTY()
	FHazeTimeLike MicSwayTimeline;
	default MicSwayTimeline.Duration = 2.f;

	UPROPERTY()
	float MaxPitchSway = 15.f;

	UPROPERTY()
	float SwaySpeedMultiplier = 1.5f;

	UPROPERTY()
	bool bGetsImpactFromAmplifier = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CompToRotate = GetAttachParent();
		InitialPitch = CompToRotate.RelativeRotation.Pitch;
		
		if (!bGetsImpactFromAmplifier)
		{
			SongReactComp = USongReactionComponent::Get(Owner);
			SongReactComp.OnPowerfulSongImpact.AddUFunction(this, n"OnPowerfulSongImpact");
		}
		else
		{
			AmpImpComp = UMiniatureAmplifierImpactComponent::Get(Owner);
			AmpImpComp.OnImpact.AddUFunction(this, n"OnAmpImpact");
		}
		
		MicSwayTimeline.BindUpdate(this, n"MicSwayTimelineUpdate");
		MicSwayTimeline.SetPlayRate(SwaySpeedMultiplier);
	
	}

	UFUNCTION()
	void OnPowerfulSongImpact(FPowerfulSongInfo Info)
	{
		SwayMicrophone(Info.Direction);
	}

	UFUNCTION()
	void OnAmpImpact(FAmplifierImpactInfo HitInfo)
	{
		SwayMicrophone(HitInfo.DirectionFromInstigator);
	}

	void SwayMicrophone(FVector Dir)
	{
		if (Dir.DotProduct(Owner.GetActorForwardVector()) < 0.f)
		{
			CurrentPitchMultiplier = MaxPitchSway;
			MicSwayTimeline.PlayFromStart();			
		}
		else
		{
			CurrentPitchMultiplier = -MaxPitchSway;
			MicSwayTimeline.PlayFromStart();
		}
	}

	UFUNCTION()
	void MicSwayTimelineUpdate(float CurrentValue)
	{
		float NewPitch = InitialPitch + FMath::Lerp(0.f, CurrentPitchMultiplier, CurrentValue);
		FRotator NewRot = FRotator(NewPitch, CompToRotate.RelativeRotation.Yaw, CompToRotate.RelativeRotation.Roll);
		CompToRotate.SetRelativeRotation(NewRot);
	}
}