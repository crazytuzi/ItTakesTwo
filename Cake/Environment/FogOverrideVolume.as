//import Cake.Environment.Sky;

struct FogData
{
    UPROPERTY()
    float FogDensity = 0.01f;

    UPROPERTY()
    float FogHeightOffset = 0.0f;

    UPROPERTY()
    float FogHeightFalloff = 0.2f;

    UPROPERTY()
    float FogMaxOpacity = 1.0f;

    UPROPERTY()
    float FogStartDistance = 2000.0f;

    UPROPERTY()
    FLinearColor FogInscatteringColor = FLinearColor(0.742727, 0.863819, 1.0, 1.0);

    UPROPERTY()
    FLinearColor FogDirectionalInscatteringColor = FLinearColor(1.0f, 0.729333f, 0.370158f, 1.0f);

    UPROPERTY()
    float FogDirectionalInscatteringStartDistance = 5000.0f;

    UPROPERTY()
    float FogDirectionalInscatteringExponent = 4.0f;
}

class UDataAssetFog : UDataAsset
{
    UPROPERTY()
    FogData Data;
}

import AFogOverrideVolume2 AddSkyFogOverrideVolume(AHazePlayerCharacter, AFogOverrideVolume2) from "Cake.Environment.Sky";
import AFogOverrideVolume2 RemoveSkyFogOverrideVolume(AHazePlayerCharacter, AFogOverrideVolume2) from "Cake.Environment.Sky";

event void OnBecomeActiveFogVolumeEvent();

class AFogOverrideVolume2 : AVolume
{
	UPROPERTY()
	int Priority = 0;
	
    UPROPERTY()
    UDataAssetFog NewFogValue;

    UPROPERTY()
    float BlendTime;


    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;
		
		auto ActiveVolume = AddSkyFogOverrideVolume(Player, this);
		if(ActiveVolume == this)
			OnBecomeActiveVolume.Broadcast();
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		auto ActiveVolume = RemoveSkyFogOverrideVolume(Player, this);
		if(ActiveVolume == this)
			OnBecomeActiveVolume.Broadcast();
    }
	
	UPROPERTY()
	OnBecomeActiveFogVolumeEvent OnBecomeActiveVolume;
}
