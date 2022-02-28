
UCLASS(NotBlueprintable, meta = ("SwarmAnimSettingsModifier"))
class AnimNotify_SwarmAnimSettingsModifier : UAnimNotifyState
{
	/* we'll lerp the from the underlying settings, which might be the base
		Settings - or another AnimNotifyModifier. */
	UPROPERTY(Category = "SwarmAnimSettingsModifier", AdvancedDisplay)
	bool bLerpTheSettings = false;

	/* 
		Controls the degree of the lerp curve.
		Value = 1 -> Linear Lerp 
		Value < 1 -> Exponential in the begin, and slows down towards the end   
		Value = 1 -> Eases in the beginning, and has an exponential growth towards the end. 
	*/
	UPROPERTY(Category = "SwarmAnimSettingsModifier", meta = (EditCondition = "bLerpTheSettings"), AdvancedDisplay)
	float LerpRamp = 1.f;

	/* Applies the modified settings on Begin and fades it away towards end of the anim state. */
	UPROPERTY(Category = "SwarmAnimSettingsModifier", meta = (EditCondition = "bLerpTheSettings"), AdvancedDisplay)
	bool bInverseLerp = false;

	// y = Alpha , x = time since TriggerTime. Alpha is clamped between 0 and 1.
	UPROPERTY(Category = "SwarmAnimSettingsModifier", AdvancedDisplay)
	FRuntimeFloatCurve LerpAlphaOverTimeCurve;

	/* The settings we wan to reach */
	UPROPERTY(meta = (DisplayName = "SettingsModifier"))
	FSwarmAnimModifierSettings SettingsModifier;

	UPROPERTY(Category = "SwarmAnimSettingsModifier",AdvancedDisplay)
	FName DebugName = NAME_None;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SwarmAnimSettingsModifier";
	}

	bool WantToOverrideSettings() const
	{
// 		return true;
		return SettingsModifier.bOverrideDamping == true
			|| SettingsModifier.bOverrideStiffness	== true 
			|| SettingsModifier.bOverrideNoiseGain	== true 
			|| SettingsModifier.bOverrideNoiseScale	== true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration) const
	{
		if (WantToOverrideSettings() == false)
			return false;

		UHazeSwarmSkeletalMeshComponent SwarmMesh = Cast<UHazeSwarmSkeletalMeshComponent>(MeshComp);

		if (SwarmMesh == nullptr)
			return false;

		FSwarmAnimModifierSettings AnimationModifierSettings = SettingsModifier;
		if (bLerpTheSettings && TotalDuration > 0.f)
		{
			AnimationModifierSettings.Duration = TotalDuration;

			// @TODO: will be off 1 frame. CurrentTime should be CurrnetTime += Dt;
			AnimationModifierSettings.CurrentTime = 0.f;

			UHazeSwarmAnimInstance HazeSwarmAnimInstance = Cast<UHazeSwarmAnimInstance>(SwarmMesh.GetAnimInstance());
			AnimationModifierSettings.TriggerTime = HazeSwarmAnimInstance.GetCurrentSwarmAnimationTime(Animation);

			AnimationModifierSettings.Alpha = 0.f;
		}
		else
		{
			AnimationModifierSettings.Alpha = 1.f;
		}

		// Need this to make sure that we don't push a 
		// notifier when playing another animation!
		AnimationModifierSettings.RefAnimation = Animation;

		SwarmMesh.PushAnimModifierSettings(AnimationModifierSettings, this);

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyTick(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float FrameDeltaTime) const
	{
		if (bLerpTheSettings == false)
			return false;

		if (WantToOverrideSettings() == false)
			return false;

		UHazeSwarmSkeletalMeshComponent SwarmMesh = Cast<UHazeSwarmSkeletalMeshComponent>(MeshComp);

		if (SwarmMesh == nullptr)
			return false;

		for (int i = SwarmMesh.ActiveAnimModifierSettings.Num() - 1; i >= 0; --i)
		{
			if (SwarmMesh.ActiveAnimModifierSettings[i].Instigator == this)
			{
				FSwarmAnimModifierSettings& Modifier = SwarmMesh.ActiveAnimModifierSettings[i];

				// This might happen if you mess with the setting in runtime.
				if (Modifier.Duration == 0.f)
					continue;

				if (LerpAlphaOverTimeCurve.GetNumKeys() > 0)
				{
					// Modifier.CurrentTime %= Modifier.Duration; // If it is looping

					UHazeSwarmAnimInstance HazeSwarmAnimInstance = Cast<UHazeSwarmAnimInstance>(SwarmMesh.GetAnimInstance());
					const float CorrectCurrentTime = HazeSwarmAnimInstance.GetCurrentSwarmAnimationTime(Animation); 

					// Handle looping animations
					if(Modifier.CurrentTime > CorrectCurrentTime && CorrectCurrentTime < Modifier.Duration)
					{
						Modifier.TriggerTime = CorrectCurrentTime;
						Modifier.CurrentTime = CorrectCurrentTime;   
						// Modifier.CurrentTime = 0.f;   
					}

					Modifier.CurrentTime = CorrectCurrentTime - Modifier.TriggerTime;

//					Modifier.CurrentTime += FrameDeltaTime;

					ensure(Modifier.CurrentTime >= 0.f);

					float LerpAlpha = LerpAlphaOverTimeCurve.GetFloatValue(Modifier.CurrentTime);
					Modifier.Alpha = FMath::Clamp(LerpAlpha, 0.f, 1.f);

					// PrintToScreen("Correct_CurrentTime : " + CorrectCurrentTime);
					// PrintToScreen("Current_Time : " + Modifier.CurrentTime);
					// PrintToScreen("" + Modifier.Alpha);
					// PrintToScreen("" + Modifier.CurrentTime + " / " + Modifier.Duration);

				}
				else
				{
					Modifier.CurrentTime += FrameDeltaTime;
					Modifier.Alpha = FMath::Clamp(Modifier.CurrentTime / Modifier.Duration, 0.f, 1.f);

					if (bInverseLerp)
						Modifier.Alpha = 1.f - Modifier.Alpha;

					Modifier.Alpha = FMath::Pow(Modifier.Alpha, LerpRamp);
				}
			}
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (WantToOverrideSettings() == false)
			return false;

		UHazeSwarmSkeletalMeshComponent SwarmMesh = Cast<UHazeSwarmSkeletalMeshComponent>(MeshComp);

		if (SwarmMesh == nullptr)
			return false;

		// for (int i = SwarmMesh.ActiveAnimModifierSettings.Num() - 1; i >= 0; --i)
		// {
		// 	if (SwarmMesh.ActiveAnimModifierSettings[i].Instigator == this)
		// 	{
		// 		FSwarmAnimModifierSettings& Modifier = SwarmMesh.ActiveAnimModifierSettings[i];

		// 		// This might happen if you mess with the setting in runtime.
		// 		if (Modifier.Duration == 0.f)
		// 			continue;
	
		// 		const float Time = Modifier.CurrentTime;
		// 		Print("" + Time);
		// 	}
		// }

		SwarmMesh.RemoveAnimModifierSettings(this);

		return true;
	}

};
