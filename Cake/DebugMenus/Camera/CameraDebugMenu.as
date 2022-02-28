import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.CameraStatics;
import Cake.DebugMenus.Camera.CameraSettingsDebugEntryWidget;
import Cake.DebugMenus.Camera.CameraDebugEntryWidget;

class UCameraDebugMenu : UHazeDebugMenuScriptBase
{
	UPROPERTY()
	TSubclassOf<UHazeCapability> CameraDebugDisplayCapabilityClass;

	UPROPERTY()
	TSubclassOf<UCameraSettingsDebugEntryWidget> SettingsEntryClass;
	TArray<UCameraSettingsDebugEntryWidget> SettingsEntries;

	UPROPERTY()
	TSubclassOf<UCameraDebugEntryWidget> CameraEntryClass;
	TArray<UCameraDebugEntryWidget> CameraEntries;

 	UFUNCTION(BlueprintPure)
	int GetMaxDebugDisplayFlag()
	{
		return ECameraDebugDisplayType::MAX - 1;
	}

    UFUNCTION()
    void OpenDefaultCameraSettingsEditor()
    {
        if (!Game::IsEditorBuild())
            return;

        FString DefaultCamSettingsName = "/Game/Blueprints/Cameras/CameraSettings/DA_CameraSpringArmSettings_Default.DA_CameraSpringArmSettings_Default";
        UHazeGameInstance Instance =  Game::GetHazeGameInstance();
        if (ensure(Instance != nullptr))
            DefaultCamSettingsName = Instance.DefaultCameraSpringArmSettings.GetPathName();
            
        Editor::OpenEditorForAsset(DefaultCamSettingsName);
    }

    UFUNCTION()
    void OpenDefaultLazyChaseSettingsEditor(EHazeCameraChaseAssistance ChaseAssistanceStrength = EHazeCameraChaseAssistance::Strong)
    {
        if (!Game::IsEditorBuild())
            return;

        FString SettingsName = "/Game/Blueprints/Cameras/LazyChase/DA_DefaultLazyChaseSettings_Weak.DA_DefaultLazyChaseSettings_Weak";
		if (ChaseAssistanceStrength == EHazeCameraChaseAssistance::Strong)
			SettingsName = "/Game/Blueprints/Cameras/LazyChase/DA_DefaultLazyChaseSettings_Strong.DA_DefaultLazyChaseSettings_Strong";
        Editor::OpenEditorForAsset(SettingsName);
    }

    FString GetInstigatorDebugDescription(UObject Instigator)
    {
        if (Instigator == nullptr)
            return "<nullptr>";

        UActorComponent CompInstigator = Cast<UActorComponent>(Instigator);
        if (CompInstigator != nullptr)
        {
            if (CompInstigator.GetOwner() == nullptr)
                return "" + Instigator + " (component with no owner!)";
            return CompInstigator.GetOwner().GetName() + " (" + Instigator.GetName() + ")";
        }

		UHazeCapability CapabilityInstigator = Cast<UHazeCapability>(Instigator);
		if ((CapabilityInstigator != nullptr) && (CapabilityInstigator.Owner != nullptr))
		{
			return Instigator.GetName() + " (on " + CapabilityInstigator.Owner.GetName() + ")";	
		}

        return Instigator.GetName();
    }   

	UFUNCTION()
	void UpdateCameraDebugInfo(AActor Actor, UHazeTextWigdet Header, UPanelWidget CameraEntryContainer)
	{
        UCameraUserComponent User = (Actor != nullptr) ? UCameraUserComponent::Get(Actor) : nullptr;
        UHazeCameraSelector CameraSelector = (User != nullptr) ? User.GetCameraSelector() : nullptr;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if ((CameraSelector == nullptr) || (Player == nullptr))
		{
			// Clear debug info
			if (Header != nullptr)
			{
				Header.SetText(FText());
			}
			if (CameraEntryContainer != nullptr)
			{
				for (int i = CameraEntryContainer.GetChildrenCount() - 1; i >= 0; i--)
				{
					if (CameraEntryContainer.GetChildAt(i).IsA(UCameraDebugEntryWidget::StaticClass()))
						CameraEntryContainer.RemoveChildAt(i);
				}
			}
			return;
		}

		if (Header != nullptr)
		{
			FString HeaderInfo = "";
			if (SceneView::IsFullScreen())
			{
				if (Player == SceneView::FullScreenPlayer)
					HeaderInfo += "<Red>FULL SCREEN VIEW</>\n\n";
				else 
					HeaderInfo += "<Red>NO SCREEN VIEW (other player has full screen)</>\n\n";
			}
			HeaderInfo += "<Yellow>Current Camera Attributes</>\n";
			HeaderInfo += "\t\t\tView FOV:      \t\t\t\t\t\t" + Player.GetViewFOV() + "\n";
			HeaderInfo += "\t\t\tView Rotation: \t\t\t\t" + Player.GetViewRotation().ToColorString() + "\n";
			HeaderInfo += "\t\t\tDesired Rotation: \t\t" + User.GetDesiredRotation().ToColorString() + "\n";
			HeaderInfo += "\t\t\tLocal Rotation:\t\t\t\t" + (Player.GetActorQuat().Inverse() * Player.GetViewRotation().Quaternion()).Rotator().ToColorString() + "\n";
			HeaderInfo += "\t\t\tInternal Rotation:\t\t\t" + User.GetBaseRotation().Rotator().ToColorString() + "\n";

			auto SpringArm = Cast<UCameraSpringArmComponent>(User.GetCurrentCameraParent(TSubclassOf<UHazeCameraParentComponent>(UCameraSpringArmComponent::StaticClass())));
			if(SpringArm != nullptr)
			{
				HeaderInfo += "\n<Yellow>SpringArm Attributes</>\n";
				HeaderInfo += "\t\t\tLocal Rotation:\t\t\t\t\t\t\t" + Player.GetActorTransform().InverseTransformRotation(SpringArm.PreviousWorldRotation).ToColorString() + "\n";
				HeaderInfo += "\t\t\tLocal Camera Location:\t" + Player.GetActorTransform().InverseTransformPositionNoScale(SpringArm.PreviousCameraLocation).ToColorString() + "\n";
				HeaderInfo += "\t\t\tLocal Pivot Location:\t\t" + Player.GetActorTransform().InverseTransformPositionNoScale(SpringArm.PreviousPivotLocation).ToColorString() + "\n";
				HeaderInfo += "\n";
				HeaderInfo += "\t\t\tWorld Rotation:\t\t\t\t\t\t\t" + SpringArm.PreviousWorldRotation.ToColorString() + "\n";
				HeaderInfo += "\t\t\tWorld Camera Location:\t" + SpringArm.PreviousCameraLocation.ToColorString() + "\n";
				HeaderInfo += "\t\t\tWorld Pivot Location:\t\t" + SpringArm.PreviousPivotLocation.ToColorString() + "\n";
				HeaderInfo += "\t\t\tTraceblock Range:\t\t\t\t\t" + ((SpringArm.TraceBlockedRange.Value < 1000000) ? ("" + SpringArm.TraceBlockedRange.Value) : "-")  + "\n";
			}
				
			HeaderInfo += "\n<Green>Active cameras:</>";
			Header.SetText(FText::FromString(HeaderInfo));
		}

        FHazeCameraSelectorDebugData SelectorDebugData;
        CameraSelector.GetDebugData(SelectorDebugData);

		if (CameraEntryContainer != nullptr)
		{
			// Create any newly needed entries
			int nNewEntries = SelectorDebugData.Cameras.Num() - CameraEntries.Num();
			for (int iNew = 0; iNew < nNewEntries; iNew++)
			{
				UCameraDebugEntryWidget NewEntry = Cast<UCameraDebugEntryWidget>(Widget::CreateWidget(CameraEntryContainer, CameraEntryClass));
				if (!ensure(NewEntry != nullptr))
					continue;
				CameraEntries.Add(NewEntry);
			}	

			// Check how many entries we currently have in container
			int NumCurrentEntries = 0;
			for (int iChild = 0; iChild < CameraEntryContainer.GetChildrenCount(); iChild++)
			{
				if (CameraEntryContainer.GetChildAt(iChild).IsA(UCameraDebugEntryWidget::StaticClass()))
					NumCurrentEntries++;
			}
			
			// Add any missing entries
			for (int i = NumCurrentEntries; i < SelectorDebugData.Cameras.Num(); i++)
			{
				CameraEntryContainer.AddChild(CameraEntries[i]);
			}

			// Update entry widgets with current data
			int iEntry = 0;
			int iChild = 0;
			for (; (iChild < CameraEntryContainer.GetChildrenCount()) && SelectorDebugData.Cameras.IsValidIndex(iEntry); iChild++)
			{
				UCameraDebugEntryWidget Entry = Cast<UCameraDebugEntryWidget>(CameraEntryContainer.GetChildAt(iChild));
				if (Entry == nullptr)
					continue; // Just in case we have something other than camera entries in the container

				const FHazeInstigatedCameraDebugData& Data = SelectorDebugData.Cameras[iEntry];
				bool bDefaultCam = (Data.Instigator == User.GetCameraSelector());
				FString Prefix = (bDefaultCam ? "<Grey>" : "");
				FString Suffix = (bDefaultCam ? "</>" : "");
				FString Desc = "";
				if (bDefaultCam)
				{
					Desc += "\t\t" + Prefix + "(Default camera)" + Suffix + "\n";
				}
				else
				{
					Desc += "\t\tInstigator: " + GetInstigatorDebugDescription(Data.Instigator) + "\n"; 
					Desc += "\t\tPriority: " + GetPriorityDebugDescription(Data.Priority) + "\n";
				}
				Desc += "\t\t" + Prefix + "Blend time: " + Data.Blend.BlendTime + Suffix;

				Entry.Update(Data, FText::FromString(Desc)); 
				iEntry++;	
			}

			// Remove any extraneous entries
			for (int iExtra = CameraEntryContainer.GetChildrenCount() - 1; iExtra >= iChild; iExtra--)
			{
				if (CameraEntryContainer.GetChildAt(iExtra).IsA(UCameraDebugEntryWidget::StaticClass()))
					CameraEntryContainer.RemoveChildAt(iExtra);
			}
		}
	}

    FString GetSettingDesc(FString InName, bool bUse, float Setting, FString Prefix, FString Suffix)
    {
        if (bUse)
            return "\t\t\t" + Prefix +  InName + ": " + Setting + Suffix + "\n";
        return "";
    }
    FString GetSettingDesc(FString InName, bool bUse, const FVector& Setting, FString Prefix, FString Suffix)
    {
        if (bUse)
            return "\t\t\t" + Prefix + InName + ": " + Suffix + Setting.ToColorString() + "\n";
        return "";
    }
    FString GetSettingDesc(FString InName, bool bUse, const FRotator& Setting, FString Prefix, FString Suffix)
    {
        if (bUse)
            return "\t\t\t" + Prefix + InName + ": " + Suffix + Setting.ToColorString() + "\n";
        return "";
    }

    TSubclassOf<UHazeCameraParentComponent> CameraSpringArmClass = UCameraSpringArmComponent::StaticClass();
    TSubclassOf<UHazeCameraParentComponent> CameraKeepInViewClass = UCameraKeepInViewComponent::StaticClass();

    FString GetSettingsDescription(const FHazeAllCameraSettings& Settings, UCameraUserComponent User, FString Prefix, FString Suffix)
    {
        FString Desc = "";
        Desc += GetSettingDesc("FOV", Settings.CameraSettings.bUseFOV, Settings.CameraSettings.FOV, Prefix, Suffix);

        if (User.HasCurrentCameraParent(CameraSpringArmClass))
        {
            Desc += GetSettingDesc("IdealDistance", Settings.SpringArmSettings.bUseIdealDistance, Settings.SpringArmSettings.IdealDistance, Prefix, Suffix);
            Desc += GetSettingDesc("MinDistance", Settings.SpringArmSettings.bUseMinDistance, Settings.SpringArmSettings.MinDistance, Prefix, Suffix);
            Desc += GetSettingDesc("PivotOffset", Settings.SpringArmSettings.bUsePivotOffset, Settings.SpringArmSettings.PivotOffset, Prefix, Suffix);
            Desc += GetSettingDesc("WorldPivotOffset", Settings.SpringArmSettings.bUseWorldPivotOffset, Settings.SpringArmSettings.WorldPivotOffset, Prefix, Suffix);
            Desc += GetSettingDesc("CameraOffset", Settings.SpringArmSettings.bUseCameraOffset, Settings.SpringArmSettings.CameraOffset, Prefix, Suffix);
            Desc += GetSettingDesc("CameraOffsetOwnerSpace", Settings.SpringArmSettings.bUseCameraOffsetOwnerSpace, Settings.SpringArmSettings.CameraOffsetOwnerSpace, Prefix, Suffix);
            Desc += GetSettingDesc("PivotLagSpeed", Settings.SpringArmSettings.bUsePivotLagSpeed, Settings.SpringArmSettings.PivotLagSpeed, Prefix, Suffix);
            Desc += GetSettingDesc("PivotLagMax", Settings.SpringArmSettings.bUsePivotLagMax, Settings.SpringArmSettings.PivotLagMax, Prefix, Suffix);
            Desc += GetSettingDesc("ChasePitchDown", Settings.SpringArmSettings.bUseChasePitchDown, Settings.SpringArmSettings.ChasePitchDown, Prefix, Suffix);
            Desc += GetSettingDesc("ChasePitchUp", Settings.SpringArmSettings.bUseChasePitchUp, Settings.SpringArmSettings.ChasePitchUp, Prefix, Suffix);
        }        
		if (User.HasCurrentCameraParent(CameraKeepInViewClass))
		{
            Desc += GetSettingDesc("MinDistance", Settings.KeepInViewSettings.bUseMinDistance, Settings.KeepInViewSettings.MinDistance, Prefix, Suffix);
            Desc += GetSettingDesc("MaxDistance", Settings.KeepInViewSettings.bUseMaxDistance, Settings.KeepInViewSettings.MaxDistance, Prefix, Suffix);
            Desc += GetSettingDesc("BufferDistance", Settings.KeepInViewSettings.bUseBufferDistance, Settings.KeepInViewSettings.BufferDistance, Prefix, Suffix);
            Desc += GetSettingDesc("AccelerationDuration", Settings.KeepInViewSettings.bUseAccelerationDuration, Settings.KeepInViewSettings.AccelerationDuration, Prefix, Suffix);
            Desc += GetSettingDesc("LookOffset", Settings.KeepInViewSettings.bUseLookOffset, Settings.KeepInViewSettings.LookOffset, Prefix, Suffix);
            Desc += GetSettingDesc("RespawnBlendInDuration", Settings.KeepInViewSettings.bUseRespawnBlendInDuration, Settings.KeepInViewSettings.RespawnBlendInDuration, Prefix, Suffix);
            Desc += GetSettingDesc("InvalidBlendOutDuration", Settings.KeepInViewSettings.bUseInvalidBlendOutDuration, Settings.KeepInViewSettings.InvalidBlendOutDuration, Prefix, Suffix);
		}

        Desc += GetSettingDesc("ClampYawLeft", Settings.ClampSettings.bUseClampYawLeft, Settings.ClampSettings.ClampYawLeft, Prefix, Suffix);
        Desc += GetSettingDesc("ClampYawRight", Settings.ClampSettings.bUseClampYawRight, Settings.ClampSettings.ClampYawRight, Prefix, Suffix);
        Desc += GetSettingDesc("ClampPitchUp", Settings.ClampSettings.bUseClampPitchUp, Settings.ClampSettings.ClampPitchUp, Prefix, Suffix);
        Desc += GetSettingDesc("ClampPitchDown", Settings.ClampSettings.bUseClampPitchDown, Settings.ClampSettings.ClampPitchDown, Prefix, Suffix);
        Desc += GetSettingDesc("CenterOffset", Settings.ClampSettings.bUseCenterOffset, Settings.ClampSettings.CenterOffset, Prefix, Suffix);
        return Desc;
    }

    FString GetPriorityDebugDescription(EHazeCameraPriority Prio)
    {
        return Debug::GetEnumDisplayName("EHazeCameraPriority", Prio); 
    }

	UFUNCTION()
	void UpdateSettingsDebugInfo(AActor Actor, UHazeTextWigdet Header, UPanelWidget SettingsEntryContainer)
	{
        UCameraUserComponent User = (Actor != nullptr) ? UCameraUserComponent::Get(Actor) : nullptr;
        UHazeCameraSettingsManager Settings = (User != nullptr) ? User.GetSettingsManager() : nullptr;
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if ((Settings == nullptr) || (Player == nullptr))
		{
			// Clear debug info
			if (Header != nullptr)
			{
				Header.SetText(FText());
			}
			if (SettingsEntryContainer != nullptr)
			{
				for (int i = SettingsEntryContainer.GetChildrenCount() - 1; i >= 0; i--)
				{
					if (SettingsEntryContainer.GetChildAt(i).IsA(UCameraSettingsDebugEntryWidget::StaticClass()))
						SettingsEntryContainer.RemoveChildAt(i);
				}
			}
			return;
		}

        FHazeCameraSettingsManagerDebugData SettingsDebugData;
        Settings.GetDebugData(SettingsDebugData);

		if (Header != nullptr)
		{
			FString HeaderInfo = "<Yellow>Current camera Settings</>\n";
			FHazeAllCameraSettings CurSettings;
			CurSettings.CameraSettings = SettingsDebugData.CurrentCameraSettings;
			CurSettings.ClampSettings = SettingsDebugData.CurrentClampSettings;
			CurSettings.SpringArmSettings = SettingsDebugData.CurrentSpringArmSettings;
			CurSettings.KeepInViewSettings = SettingsDebugData.CurrentKeepInViewSettings;
			HeaderInfo += GetSettingsDescription(CurSettings, User, "", "");
			HeaderInfo += "\n<Yellow>Active camera settings:</>";
			Header.SetText(FText::FromString(HeaderInfo));
		}
		
		if (SettingsEntryContainer != nullptr)
		{
			// Create any newly needed entries
			int nNewEntries = SettingsDebugData.Settings.Num() - SettingsEntries.Num();
			for (int iNew = 0; iNew < nNewEntries; iNew++)
			{
				UCameraSettingsDebugEntryWidget NewEntry = Cast<UCameraSettingsDebugEntryWidget>(Widget::CreateWidget(SettingsEntryContainer, SettingsEntryClass));
				if (!ensure(NewEntry != nullptr))
					continue;
				SettingsEntries.Add(NewEntry);
			}	

			// Check how many entries we currently have in container
			int NumCurrentEntries = 0;
			for (int iChild = 0; iChild < SettingsEntryContainer.GetChildrenCount(); iChild++)
			{
				if (SettingsEntryContainer.GetChildAt(iChild).IsA(UCameraSettingsDebugEntryWidget::StaticClass()))
					NumCurrentEntries++;
			}
			
			// Add any missing entries
			for (int i = NumCurrentEntries; i < SettingsDebugData.Settings.Num(); i++)
			{
				SettingsEntryContainer.AddChild(SettingsEntries[i]);
			}

			// Update entry widgets with current data
			int iEntry = 0;
			int iChild = 0;
			for (; (iChild < SettingsEntryContainer.GetChildrenCount()) && SettingsDebugData.Settings.IsValidIndex(iEntry); iChild++)
			{
				UCameraSettingsDebugEntryWidget Entry = Cast<UCameraSettingsDebugEntryWidget>(SettingsEntryContainer.GetChildAt(iChild));
				if (Entry == nullptr)
					continue; // Just in case we haev something other than settings entries in the container

				// Build description of settings
				FString Desc = "";
				const FHazeInstigatedCameraSettingsDebugData& Data = SettingsDebugData.Settings[iEntry];
				bool bDefault = (Data.Instigator == Game::GetHazeGameInstance());
				FString Prefix = (bDefault ? "<Grey>" : (Data.bIsBlendingOut ? "<LightGrey>" : ""));
				FString Suffix = (bDefault || Data.bIsBlendingOut ? "</>" : "");

				// Settings with an asset will be headed by a button allowing you to open the editor for that asset.
				if (Data.SettingsAsset == nullptr)
					Desc += Prefix + "Custom settings (no data asset):"  + Suffix + "\n";
				if (Data.Blend.Type == EHazeCameraBlendType::Additive)
					Desc += "\t\t(Additive blend)\n"; 
				if (Data.Blend.Type == EHazeCameraBlendType::ManualFraction)
					Desc += "\t\t(Manual fraction blend: " + Data.Blend.Fraction + ")\n"; 
				FString OverrideSettingsDesc = GetSettingsDescription(Data.OverrideSettings, User, Prefix, Suffix);
				if (!OverrideSettingsDesc.IsEmpty())
					Desc += OverrideSettingsDesc; // Settings desc will end with a newline
				if (bDefault)
				{
					Desc += "\t\t" + Prefix + "(Default settings)" + Suffix + "\n";
				}
				else
				{
					Desc += "\t\t" + Prefix + "Instigator: " + GetInstigatorDebugDescription(Data.Instigator) + Suffix + "\n"; 
					Desc += "\t\t" + Prefix + "Priority: " + GetPriorityDebugDescription(Data.Priority) + Suffix + "\n";
				}
				Desc += "\t\t" + Prefix + "Blend time:" + Data.Blend.BlendTime + Suffix;
				if (Data.bIsBlendingOut)
					Desc += "\n\t\t" + Prefix + "Blending out in " + Data.RemainingDuration + " seconds." + Suffix;

				Entry.Update(Data, FText::FromString(Desc)); 
				iEntry++;	
			}

			// Remove any extraneous entries
			for (int iExtra = SettingsEntryContainer.GetChildrenCount() - 1; iExtra >= iChild; iExtra--)
			{
				if (SettingsEntryContainer.GetChildAt(iExtra).IsA(UCameraSettingsDebugEntryWidget::StaticClass()))
					SettingsEntryContainer.RemoveChildAt(iExtra);
			}
		}
	}

    UFUNCTION(BlueprintPure)
    FString GetCameraPointOfInterestDebugInfo(AActor Actor)
    {
        if (Actor == nullptr)
            return "";

        UCameraUserComponent User = UCameraUserComponent::Get(Actor);
        if (User == nullptr)
            return "<Invalid camera user>";

        UHazePointOfInterestManager POIManager = User.GetPointsOfInterest();
        if (POIManager == nullptr)
            return "<Camera user with no point of interest manager! Yell OOOLSSON at the top of your lungs!>";

		FHazeCameraPointOfInterestDebugData DebugData;
		POIManager.GetDebugData(DebugData);	

        FString Info = "<Blue>Active points of interest:</>";
        for (FHazeInstigatedPointOfInterestDebugData Data : DebugData.PointsOfInterest)
        {
			if (!Data.PointOfInterest.FocusTarget.IsValid())
				continue;

			Info += "\nFocus Target: ";
            if (Data.PointOfInterest.FocusTarget.Component != nullptr)
                Info += Data.PointOfInterest.FocusTarget.Component.Owner.GetName() + " (" + Data.PointOfInterest.FocusTarget.Component.GetName() + ")";
            else if (Data.PointOfInterest.FocusTarget.Actor != nullptr)
                Info += Data.PointOfInterest.FocusTarget.Actor.GetName();
            else
                Info += Data.PointOfInterest.FocusTarget.WorldOffset.ToString();
			if (Data.PointOfInterest.bMatchFocusDirection)
				Info += "\n\t\t(Match direction)";
            Info += "\n\t\tInstigator: " + GetInstigatorDebugDescription(Data.Instigator); 
            Info += "\n\t\tPriority: " + GetPriorityDebugDescription(Data.Priority);
        }

        return Info;
    }

    UFUNCTION(BlueprintPure)
    FString GetModifiersDebugInfo(AActor Actor)
    {
        if (Actor == nullptr)
            return "";

        UCameraUserComponent User = UCameraUserComponent::Get(Actor);
        if (User == nullptr)
            return "<Invalid camera user>";

        UHazeCameraModifierManager Modifiers = User.GetModifier();
        if (Modifiers == nullptr)
            return "<Camera user with no selector! Yell OOOLSSON at the top of your lungs!>";
		
		FHazeCameraModifiersDebugData DebugData;
		Modifiers.GetDebugData(DebugData);

		FString Info = "<Red>Active camera shakes:</>";
		for (UCameraModifier Mod : DebugData.Modifiers)
		{	
			UCameraModifier_CameraShake Shaker = Cast<UCameraModifier_CameraShake>(Mod);
			if (Shaker != nullptr)
			{
				for (const FActiveCameraShakeInfo& Shake : Shaker.ActiveShakes)
					Info += "\n\t" + Shake.ShakeInstance.GetName(); 
			}
		}
		Info += "\n\n<Red>Active camera animations:</>";
		for (UCameraAnimInst Anim : DebugData.Animations)
		{
			if (Anim != nullptr)
				Info += "\n\t" + Anim.GetName();
		}
		return Info;
	}

	UFUNCTION()
	void EnableDebugDisplayType(AActor Actor, ECameraDebugDisplayType Flag)
	{
		if (Actor == nullptr)
			return;

		UCameraUserComponent User = UCameraUserComponent::Get(Actor);
		if (User == nullptr)
			return;

		if (!User.HasDebugDisplayFlags() && CameraDebugDisplayCapabilityClass.IsValid())
		{
			AHazeActor HazeActor = Cast<AHazeActor>(Actor);
			if(HazeActor != nullptr) 
				HazeActor.AddCapability(CameraDebugDisplayCapabilityClass);
		}

		// Add flag
		User.EnableDebugDisplay(Flag);
	}

	UFUNCTION()
	void DisableDebugDisplayType(AActor Actor, ECameraDebugDisplayType Flag)
	{
		if (Actor == nullptr)
			return;

		UCameraUserComponent User = UCameraUserComponent::Get(Actor);
		if (User == nullptr)
			return;

		// Remove flag
		User.DisableDebugDisplay(Flag);

		if (!User.HasDebugDisplayFlags() && CameraDebugDisplayCapabilityClass.IsValid())
		{
			AHazeActor HazeActor = Cast<AHazeActor>(Actor);
			if (HazeActor != nullptr)
				HazeActor.RemoveCapability(CameraDebugDisplayCapabilityClass);
		}
	}

	UFUNCTION()
	void ClearDebugDisplay()
	{
		UCameraUserComponent CodyUser = UCameraUserComponent::Get(Game::GetCody());
		UCameraUserComponent MayUser = UCameraUserComponent::Get(Game::GetMay());
		if (CodyUser != nullptr)
			CodyUser.ClearDebugDisplayFlags();
		if (MayUser != nullptr)
			MayUser.ClearDebugDisplayFlags();
	}

	UFUNCTION()
	void SetSpringArmBlockedFraction(AActor Actor, float Fraction)
	{
#if TEST
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player != Actor)
				SetSpringArmBlockedFractionInternal(Actor, 1.f);
		}
		SetSpringArmBlockedFractionInternal(Actor, Fraction);
#endif
	}

	void SetSpringArmBlockedFractionInternal(AActor Actor, float Fraction)
	{
#if TEST
		UCameraUserComponent User = UCameraUserComponent::Get(Actor);
		UCameraSpringArmComponent Springarm = (User == nullptr) ? nullptr : Cast<UCameraSpringArmComponent>(User.GetCurrentCameraParent(TSubclassOf<UHazeCameraParentComponent>(UCameraSpringArmComponent::StaticClass())));
		if (Springarm == nullptr)
			return;
		Springarm.TestBlockedRangeFraction = Fraction;
#endif
	}

	UFUNCTION()
	void CopyCameraTransform(AHazePlayerCharacter Player)
	{
		CopyCameraTransformToClipboard(Player);
	}

	UFUNCTION()
	void SetAnimationInspectCamera(bool bEnabled)
	{
		UCameraUserComponent User = UCameraUserComponent::Get(Game::GetMay());
		if (User != nullptr)
		{
			// Setting this for one player will propagate it to both by DebugAnimationInspectionCameraCapability
			if (bEnabled)
				User.EnableDebugDisplay(ECameraDebugDisplayType::AnimationInspect);
			else
				User.DisableDebugDisplay(ECameraDebugDisplayType::AnimationInspect);
		}
	}

    UFUNCTION()
    void OpenAnimationInspectSettingsEditor()
    {
        if (!Game::IsEditorBuild())
            return;

        Editor::OpenEditorForAsset("/Game/Blueprints/Cameras/CameraSettings/DA_CamSettings_AnimationInspection.DA_CamSettings_AnimationInspection");
    }

	UFUNCTION(BlueprintPure)
	bool IsUsingAnimationInspectionCamera()
	{
		UCameraUserComponent User = (Game::GetMay() == nullptr) ? nullptr : UCameraUserComponent::Get(Game::GetMay());
		if (User == nullptr)
			return false;
		return User.ShouldDebugDisplay(ECameraDebugDisplayType::AnimationInspect);
	}

	UFUNCTION(BlueprintPure)
	float GetBlendTimeOverride(AActor Actor)
	{
		UCameraUserComponent User = (Actor != nullptr) ? UCameraUserComponent::Get(Actor) : nullptr;
		UHazeCameraSelector CamSelector = (User != nullptr) ? User.GetCameraSelector() : nullptr;
		if (CamSelector == nullptr)
			return -1.f;		

		return CamSelector.DebugBlendTimeOverride;
	}

	UFUNCTION(BlueprintCallable)
	void SetBlendTimeOverride(AActor Actor, float BlendTimeOverride)
	{
		UCameraUserComponent User = (Actor != nullptr) ? UCameraUserComponent::Get(Actor) : nullptr;
		UHazeCameraSelector CamSelector = (User != nullptr) ? User.GetCameraSelector() : nullptr;
		if (CamSelector == nullptr)
			return;		

		CamSelector.DebugBlendTimeOverride = BlendTimeOverride;
	}

	UFUNCTION(BlueprintPure)
	EHazeCameraBlendoutBehaviour GetBlendOutBehaviourOverride(AActor Actor)
	{
		UCameraUserComponent User = (Actor != nullptr) ? UCameraUserComponent::Get(Actor) : nullptr;
		UHazeCameraSelector CamSelector = (User != nullptr) ? User.GetCameraSelector() : nullptr;
		if (CamSelector == nullptr)
			return EHazeCameraBlendoutBehaviour::Invalid;		

		return CamSelector.DebugBlendOutBehaviourOverride;
	}

	UFUNCTION(BlueprintCallable)
	void SetBlendOutBehaviourOverride(AActor Actor, EHazeCameraBlendoutBehaviour Behaviour)
	{
		UCameraUserComponent User = (Actor != nullptr) ? UCameraUserComponent::Get(Actor) : nullptr;
		UHazeCameraSelector CamSelector = (User != nullptr) ? User.GetCameraSelector() : nullptr;
		if (CamSelector == nullptr)
			return;		

		CamSelector.DebugBlendOutBehaviourOverride = Behaviour;
	}

	UFUNCTION(BlueprintCallable)
	TArray<FString> GetBlendOutBehaviourOverrideOptions()
	{
		TArray<FString> Options;
		for (int i = 0; EHazeCameraBlendoutBehaviour(i) <= EHazeCameraBlendoutBehaviour::Custom; i++)
		{
			FString OptionName = "" + EHazeCameraBlendoutBehaviour(i);	
			FString Dummy; 
			OptionName.Split("::", Dummy, OptionName);
			OptionName.Split("(", OptionName, Dummy);
			Options.Add(OptionName);
		}
		return Options;
	}
}

