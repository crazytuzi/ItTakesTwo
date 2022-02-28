import Vino.Time.ActorTimeDilationComponent;
import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.HazeAudioManager.HazeAudioManager;

/* Apply a temporary time dilation effect to a specific actor for a specific duration.
   The curve is applied as a multiplier to the time dilation amount over the duration.

   If multiple time dilation effects are active at the same time, the slowest dilation
   will be used.
*/
UFUNCTION(Category = "Time Dilation")
void AddTimeDilationEffectToActor(AHazeActor Actor, float Duration, float TimeDilation = 1.f, UCurveFloat Curve = nullptr, bool bAllowTimeDilationAudio = true)
{
    auto DilationComp = UActorTimeDilationComponent::GetOrCreate(Actor);
    DilationComp.AddTimeDilation(Duration, TimeDilation, Curve);

	if(!bAllowTimeDilationAudio)
		return;

	// Not handling objects with more than one haze ak comp right now, let's see if this comes back to bite me in the ass... (J.S)
	UHazeAkComponent HazeAkComp = UHazeAkComponent::Get(Actor);
	if(HazeAkComp != nullptr)
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::ModifiedTimeDilationOverride, TimeDilation);	

	auto AudioManager = Cast<UHazeAudioManager>(Audio::GetAudioManager());
	if(AudioManager != nullptr)
		AudioManager.RequestEnterSlowMo(Actor, TimeDilation);
}

/* Apply a time dilation effect to an actor managed by an instigator.

   If multiple time dilation effects are active at the same time, the slowest dilation
   will be used.
*/
UFUNCTION(Category = "Time Dilation")
void ModifyActorTimeDilation(AHazeActor Actor, float TimeDilation, UObject Instigator, bool bAllowTimeDilationAudio = true)
{
    auto DilationComp = UActorTimeDilationComponent::GetOrCreate(Actor);
    DilationComp.ModifyTimeDilation(TimeDilation, Instigator);


	if(!bAllowTimeDilationAudio)
		return;

	// Not handling objects with more than one haze ak comp right now, let's see if this comes back to bite me in the ass... (J.S)
	UHazeAkComponent HazeAkComp = UHazeAkComponent::Get(Actor);
	if(HazeAkComp != nullptr)
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::ModifiedTimeDilationOverride, TimeDilation);	

	auto AudioManager = Cast<UHazeAudioManager>(Audio::GetAudioManager());
	if(AudioManager != nullptr)
		AudioManager.RequestEnterSlowMo(Actor, TimeDilation);
}

/* Clear a previously applied time dilation effect with an instigator from an actor.
*/
UFUNCTION(Category = "Time Dilation")
void ClearActorTimeDilation(AHazeActor Actor, UObject Instigator)
{
    auto DilationComp = UActorTimeDilationComponent::GetOrCreate(Actor);
    DilationComp.ClearTimeDilation(Instigator);

	UHazeAkComponent HazeAkComp = UHazeAkComponent::Get(Actor);
	if(HazeAkComp != nullptr)
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::ModifiedTimeDilationOverride, 1.f);	

	auto AudioManager = Cast<UHazeAudioManager>(Audio::GetAudioManager());
	if(AudioManager != nullptr)
		AudioManager.RequestExitSlowMo(Actor);		
}