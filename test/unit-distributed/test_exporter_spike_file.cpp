#include "../gtest.h"
#include "test.hpp"

#include <cstdio>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include <arbor/distributed_context.hpp>
#include <arbor/spike.hpp>

#include <communication/communicator.hpp>
#include <io/exporter_spike_file.hpp>

class exporter_spike_file_fixture : public ::testing::Test {
protected:
    using exporter_type = arb::io::exporter_spike_file;

    std::string file_name_;
    std::string path_;
    std::string extension_;
    unsigned index_;

    exporter_spike_file_fixture() :
        file_name_("spikes_exporter_spike_file_fixture"),
        path_("./"),
        extension_("gdf"),
        index_(g_context.id())
    {}

    std::string get_standard_file_name() {
        return exporter_type::create_output_file_path(file_name_, path_, extension_, index_);
    }

    void SetUp() {
        // code here will execute just before the test ensues 
    }

    void TearDown() {
        // delete the start create file
        std::remove(get_standard_file_name().c_str());
    }

    ~exporter_spike_file_fixture()
    {}
};

TEST_F(exporter_spike_file_fixture, constructor) {
    // Create an exporter, and overwrite if neccesary.
    exporter_type exporter(file_name_, path_, extension_, index_, true);

    // Assert that the output file exists
    {
        std::ifstream f(get_standard_file_name());
        ASSERT_TRUE(f.good());
    }

    // Create a new exporter with overwrite false. This should throw, because an
    // outut file with the same name is in use by exporter.
    try {
        exporter_type exporter1(file_name_, path_, extension_, index_, false);
        FAIL() << "expected a file already exists error";
    }
    catch (const std::runtime_error& err) {
        EXPECT_EQ(
            err.what(),
            "Tried opening file for writing but it exists and over_write is false: " +
            get_standard_file_name()
        );
    }
    catch (...) {
        FAIL() << "expected a file already exists error";
    }
}

TEST_F(exporter_spike_file_fixture, create_output_file_path) {
    // Create some random paths, no need for fancy tests here
    std::string produced_filename =
        exporter_type::create_output_file_path("spikes", "./", "gdf", 0);
    EXPECT_STREQ(produced_filename.c_str(), "./spikes_0.gdf");

    produced_filename =
        exporter_type::create_output_file_path("a_name", "../../", "txt", 5);
    EXPECT_STREQ(produced_filename.c_str(), "../../a_name_5.txt");
}

TEST_F(exporter_spike_file_fixture, do_export) {
    {
        exporter_type exporter(file_name_, path_, extension_, g_context.id());

        // Create some spikes
        std::vector<arb::spike> spikes;
        spikes.push_back({ { 0, 0 }, 0.0 });
        spikes.push_back({ { 0, 0 }, 0.1 });
        spikes.push_back({ { 1, 0 }, 1.0 });
        spikes.push_back({ { 1, 0 }, 1.1 });

        // now do the export
        exporter.output(spikes);
    }

    // Test if we have spikes in the file?
    std::ifstream f(get_standard_file_name());
    EXPECT_TRUE(f.good());

    std::string line;

    EXPECT_TRUE(std::getline(f, line));
    EXPECT_STREQ(line.c_str(), "0 0.0000");
    EXPECT_TRUE(std::getline(f, line));
    EXPECT_STREQ(line.c_str(), "0 0.1000");
    EXPECT_TRUE(std::getline(f, line));
    EXPECT_STREQ(line.c_str(), "1 1.0000");
    EXPECT_TRUE(std::getline(f, line));
    EXPECT_STREQ(line.c_str(), "1 1.1000");
}