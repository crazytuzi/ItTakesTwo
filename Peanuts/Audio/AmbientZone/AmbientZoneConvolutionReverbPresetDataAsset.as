import Peanuts.Audio.AudioStatics;

class UHazeAmbientZoneConvolutionReverbPresetDataAsset : UHazeAmbZoneReverbDataAsset
{
	TArray<UObject> AmbientZones;	

	UPROPERTY(Category = "Reverb", meta=(ClampMin="-96.0", UIMin="-96.0", ClampMax="24.f", UIMax="24.f"))
	float IRVolume = 0.f;
		
	UPROPERTY(Category = "Speaker Levels", meta=(ClampMin="-96.0", UIMin="-96.0", ClampMax="0.0", UIMax="0.0"))
	float Front = 0.f;
	UPROPERTY(Category = "Speaker Levels", meta=(ClampMin="-96.0", UIMin="-96.0", ClampMax="0.0", UIMax="0.0"))
	float Rear = 0.f;
	UPROPERTY(Category = "Speaker Levels", meta=(ClampMin="-96.0", UIMin="-96.0", ClampMax="0.0", UIMax="0.0"))
	float Center = 0.f;

	UPROPERTY(Category = "Output", meta=(ClampMin="-96.0", UIMin="-96.0", ClampMax="0.0", UIMax="0.0"))
	float Reverb = -20.f;

}